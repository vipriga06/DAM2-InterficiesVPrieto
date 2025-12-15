package com.xat_ieti;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

import org.json.JSONObject;

public class OllamaService {
    private static final String OLLAMA_BASE_URL = "http://localhost:11434";
    private static final String TEXT_MODEL = "gemma3:1b";
    private static final String IMAGE_MODEL = "llava";
    private final HttpClient httpClient;

    public OllamaService() {
        this.httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .version(HttpClient.Version.HTTP_1_1)
            .build();
    }

    public interface ResponseCallback {
        void onChunkReceived(String chunk);
        void onComplete();
        void onError(String error);
    }

    public boolean isOllamaRunning() {
        try {
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(OLLAMA_BASE_URL + "/api/tags"))
                .timeout(Duration.ofSeconds(5))
                .GET()
                .build();
            
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            System.out.println("Ollama status check: " + response.statusCode());
            return response.statusCode() == 200;
        } catch (Exception e) {
            System.err.println("Ollama connection error: " + e.getMessage());
            return false;
        }
    }

    public String getTextModelName() {
        return TEXT_MODEL;
    }

    public String getImageModelName() {
        return IMAGE_MODEL;
    }

    public void streamTextResponse(String message, ResponseCallback callback) {
        String requestBody = String.format(
            "{\"model\": \"%s\", \"prompt\": \"%s\", \"stream\": true}",
            TEXT_MODEL,
            escapeJsonString(message)
        );

        System.out.println("Sending request to model: " + TEXT_MODEL);

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create(OLLAMA_BASE_URL + "/api/generate"))
            .header("Content-Type", "application/json")
            .timeout(Duration.ofMinutes(5))
            .POST(HttpRequest.BodyPublishers.ofString(requestBody))
            .build();

        httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
            .thenAccept(response -> {
                System.out.println("Response status: " + response.statusCode());
                
                if (response.statusCode() == 200) {
                    String body = response.body();
                    
                    String[] lines = body.split("\n");
                    for (String line : lines) {
                        if (!line.trim().isEmpty()) {
                            processStreamLine(line, callback);
                        }
                    }
                } else {
                    String errorMsg = "HTTP Error: " + response.statusCode() + " - " + response.body();
                    System.err.println(errorMsg);
                    callback.onError(errorMsg);
                }
            })
            .exceptionally(e -> {
                String errorMsg = "Request failed: " + e.getMessage();
                System.err.println(errorMsg);
                e.printStackTrace();
                callback.onError(errorMsg);
                return null;
            });
    }

    private void processStreamLine(String line, ResponseCallback callback) {
        try {
            JSONObject json = new JSONObject(line);
            
            if (json.has("response")) {
                String response = json.getString("response");
                if (!response.isEmpty()) {
                    callback.onChunkReceived(response);
                }
            }
            
            if (json.has("done") && json.getBoolean("done")) {
                System.out.println("Stream complete");
                callback.onComplete();
            }
        } catch (Exception e) {
            System.err.println("JSON parsing error, trying manual parse: " + e.getMessage());
            
            if (line.contains("\"response\"")) {
                try {
                    int start = line.indexOf("\"response\":\"") + 12;
                    int nextQuote = line.indexOf("\"", start);
                    
                    if (start > 11 && nextQuote > start) {
                        String response = line.substring(start, nextQuote);
                        String decoded = response
                            .replace("\\n", "\n")
                            .replace("\\r", "\r")
                            .replace("\\t", "\t")
                            .replace("\\\"", "\"")
                            .replace("\\\\", "\\");
                        
                        if (!decoded.isEmpty()) {
                            callback.onChunkReceived(decoded);
                        }
                    }
                } catch (Exception ex) {
                    System.err.println("Manual parse also failed: " + ex.getMessage());
                }
            }
            
            if (line.contains("\"done\":true")) {
                callback.onComplete();
            }
        }
    }

    public String getImageResponse(String imageBase64, String question) throws Exception {
        String requestBody = String.format(
            "{\"model\": \"%s\", \"prompt\": \"%s\", \"images\": [\"%s\"], \"stream\": false}",
            IMAGE_MODEL,
            escapeJsonString(question),
            imageBase64
        );

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create(OLLAMA_BASE_URL + "/api/generate"))
            .header("Content-Type", "application/json")
            .timeout(Duration.ofMinutes(5))
            .POST(HttpRequest.BodyPublishers.ofString(requestBody))
            .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() == 200) {
            return extractResponseFromJson(response.body());
        } else {
            throw new RuntimeException("HTTP Error: " + response.statusCode() + " - " + response.body());
        }
    }

    private String extractResponseFromJson(String jsonStr) {
        try {
            JSONObject json = new JSONObject(jsonStr);
            if (json.has("response")) {
                return json.getString("response");
            }
            return "Error: No response field in JSON";
        } catch (Exception e) {
            return "Error parsing response: " + e.getMessage();
        }
    }

    private String escapeJsonString(String input) {
        return input.replace("\\", "\\\\")
                   .replace("\"", "\\\"")
                   .replace("\n", "\\n")
                   .replace("\r", "\\r")
                   .replace("\t", "\\t");
    }
}