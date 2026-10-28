package com.schoolexam;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;

public class AppServer {
    private static final String DB_URL = "jdbc:mysql://localhost:3306/school_exam_db?useSSL=false&allowPublicKeyRetrieval=true";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "password";

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        server.createContext("/api/data", new ApiHandler());
        server.createContext("/", new StaticHandler());
        server.setExecutor(null);
        server.start();
        System.out.println("Server running on http://localhost:8080/");
    }

    static class ApiHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            exchange.getResponseHeaders().add("Access-Control-Allow-Origin", "*");
            exchange.getResponseHeaders().add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
            exchange.getResponseHeaders().add("Access-Control-Allow-Headers", "Content-Type");
            exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");

            String method = exchange.getRequestMethod();

            if (method.equalsIgnoreCase("OPTIONS")) {
                exchange.sendResponseHeaders(204, -1);
                return;
            }

            String query = exchange.getRequestURI().getQuery();
            String table = "Department";
            if (query != null && query.contains("table=")) {
                for (String param : query.split("&")) {
                    if (param.startsWith("table=")) {
                        table = param.split("=")[1];
                    }
                }
            }

            if (!table.matches("^[a-zA-Z_]+$")) {
                sendJsonResponse(exchange, 400, "{\"error\":\"Invalid table name.\"}");
                return;
            }

            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {

                    if (method.equalsIgnoreCase("GET")) {
                        handleGet(conn, table, exchange);
                    } else if (method.equalsIgnoreCase("POST")) {
                        handlePost(conn, table, exchange);
                    } else if (method.equalsIgnoreCase("PUT")) {
                        handlePut(conn, table, exchange);
                    } else if (method.equalsIgnoreCase("DELETE")) {
                        handleDelete(conn, table, exchange);
                    }
                }
            } catch (Exception e) {
                sendJsonResponse(exchange, 500, "{\"error\":\"" + e.getMessage().replace("\"", "'").replace("\n", " ") + "\"}");
            }
        }

        private void handleGet(Connection conn, String table, HttpExchange exchange) throws Exception {
            List<Map<String, Object>> rows = new ArrayList<>();
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT * FROM `" + table + "`")) {

                ResultSetMetaData metaData = rs.getMetaData();
                int columnCount = metaData.getColumnCount();

                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= columnCount; i++) {
                        row.put(metaData.getColumnName(i), rs.getObject(i));
                    }
                    rows.add(row);
                }
            }
            sendJsonResponse(exchange, 200, toJSON(rows));
        }

        private void handlePost(Connection conn, String table, HttpExchange exchange) throws Exception {
            String body = readRequestBody(exchange);
            Map<String, String> data = parseSimpleJson(body);

            if (data.isEmpty()) {
                sendJsonResponse(exchange, 400, "{\"error\":\"No data provided\"}");
                return;
            }

            StringBuilder cols = new StringBuilder();
            StringBuilder params = new StringBuilder();
            List<String> values = new ArrayList<>();

            for (Map.Entry<String, String> entry : data.entrySet()) {
                if (cols.length() > 0) { cols.append(","); params.append(","); }
                cols.append("`").append(entry.getKey()).append("`");
                params.append("?");
                values.add(entry.getValue());
            }

            String sql = "INSERT INTO `" + table + "` (" + cols + ") VALUES (" + params + ")";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                for (int i = 0; i < values.size(); i++) {
                    pstmt.setString(i + 1, values.get(i).isEmpty() ? null : values.get(i));
                }
                pstmt.executeUpdate();
            }
            sendJsonResponse(exchange, 200, "{\"message\":\"Record inserted successfully\"}");
        }

        private void handlePut(Connection conn, String table, HttpExchange exchange) throws Exception {
            String body = readRequestBody(exchange);
            Map<String, String> data = parseSimpleJson(body);

            String pkColumn = getPrimaryKeyColumn(conn, table);
            String pkValue = data.remove(pkColumn);

            if (pkValue == null || data.isEmpty()) {
                sendJsonResponse(exchange, 400, "{\"error\":\"Primary key missing or no fields to update\"}");
                return;
            }

            StringBuilder setClause = new StringBuilder();
            List<String> values = new ArrayList<>();

            for (Map.Entry<String, String> entry : data.entrySet()) {
                if (setClause.length() > 0) setClause.append(", ");
                setClause.append("`").append(entry.getKey()).append("` = ?");
                values.add(entry.getValue());
            }

            String sql = "UPDATE `" + table + "` SET " + setClause + " WHERE `" + pkColumn + "` = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                int idx = 1;
                for (String val : values) {
                    pstmt.setString(idx++, val.isEmpty() ? null : val);
                }
                pstmt.setString(idx, pkValue);
                pstmt.executeUpdate();
            }
            sendJsonResponse(exchange, 200, "{\"message\":\"Record updated successfully\"}");
        }

        private void handleDelete(Connection conn, String table, HttpExchange exchange) throws Exception {
            String query = exchange.getRequestURI().getQuery();
            String id = null;
            if (query != null) {
                for (String param : query.split("&")) {
                    if (param.startsWith("id=")) {
                        id = param.split("=")[1];
                    }
                }
            }

            if (id == null) {
                sendJsonResponse(exchange, 400, "{\"error\":\"Missing ID for deletion\"}");
                return;
            }

            String pkColumn = getPrimaryKeyColumn(conn, table);
            String sql = "DELETE FROM `" + table + "` WHERE `" + pkColumn + "` = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, id);
                pstmt.executeUpdate();
            }
            sendJsonResponse(exchange, 200, "{\"message\":\"Record deleted successfully\"}");
        }

        private String getPrimaryKeyColumn(Connection conn, String table) throws Exception {
            DatabaseMetaData meta = conn.getMetaData();
            try (ResultSet rs = meta.getPrimaryKeys(null, null, table)) {
                if (rs.next()) {
                    return rs.getString("COLUMN_NAME");
                }
            }
            return "ID";
        }

        private String readRequestBody(HttpExchange exchange) throws IOException {
            InputStream is = exchange.getRequestBody();
            return new String(is.readAllBytes(), StandardCharsets.UTF_8);
        }

        private Map<String, String> parseSimpleJson(String json) {
            Map<String, String> map = new LinkedHashMap<>();
            json = json.trim();
            if (json.startsWith("{")) json = json.substring(1);
            if (json.endsWith("}")) json = json.substring(0, json.length() - 1);

            String[] pairs = json.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)");
            for (String pair : pairs) {
                String[] kv = pair.split(":(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)", 2);
                if (kv.length == 2) {
                    String key = kv[0].trim().replaceAll("^\"|\"$", "");
                    String val = kv[1].trim().replaceAll("^\"|\"$", "");
                    map.put(key, val);
                }
            }
            return map;
        }

        private void sendJsonResponse(HttpExchange exchange, int statusCode, String jsonResponse) throws IOException {
            byte[] bytes = jsonResponse.getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(statusCode, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        }
    }

    static class StaticHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String path = exchange.getRequestURI().getPath();
            if (path.equals("/")) {
                path = "/index.html";
            }
            
            java.io.File file = java.nio.file.Paths.get("webapp", path).toFile();

            if (file.exists() && !file.isDirectory()) {
                byte[] bytes = java.nio.file.Files.readAllBytes(file.toPath());
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(bytes);
                }
            } else {
                String notFound = "404 Not Found. Checked path: " + file.getAbsolutePath();
                exchange.sendResponseHeaders(404, notFound.length());
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(notFound.getBytes());
                }
            }
        }
    }

    private static String toJSON(List<Map<String, Object>> rows) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < rows.size(); i++) {
            sb.append("{");
            Map<String, Object> row = rows.size() > 0 ? rows.get(i) : new HashMap<>();
            int j = 0;
            for (Map.Entry<String, Object> entry : row.entrySet()) {
                sb.append("\"").append(entry.getKey()).append("\":");
                Object val = entry.getValue();
                if (val == null) sb.append("null");
                else if (val instanceof Number || val instanceof Boolean) sb.append(val);
                else sb.append("\"").append(val.toString().replace("\"", "\\\"")).append("\"");
                if (++j < row.size()) sb.append(",");
            }
            sb.append("}");
            if (i < rows.size() - 1) sb.append(",");
        }
        sb.append("]");
        return sb.toString();
    }
}