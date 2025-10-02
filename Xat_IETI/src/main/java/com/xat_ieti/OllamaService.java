package com.xat_ieti;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class OllamaService {
    private static final String OLLAMA_BASE_URL = "http://localhost:11434";
    private final HttpClient httpClient;

    public OllamaService() {
        this.httpClient = HttpClient.newHttpClient();
    }

    public interface ResponseCallback {
        void onChunkReceived(String chunk);
        void onComplete();
        void onError(String error);
    }

    public void streamTextResponse(String message, ResponseCallback callback) {
        String requestBody = String.format(
            "{\"model\": \"gemma3:1b\", \"prompt\": \"%s\", \"stream\": true}",
            escapeJsonString(message)
        );

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create(OLLAMA_BASE_URL + "/api/generate"))
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(requestBody))
            .build();

        httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofLines())
            .thenAccept(response -> {
                if (response.statusCode() == 200) {
                    response.body().forEach(line -> {
                        if (!line.trim().isEmpty()) {
                            processStreamLine(line, callback);
                        }
                    });
                } else {
                    callback.onError("HTTP Error: " + response.statusCode());
                }
            })
            .exceptionally(e -> {
                callback.onError("Request failed: " + e.getMessage());
                return null;
            });
    }

    private void processStreamLine(String line, ResponseCallback callback) {
        try {
            // Parseo manual del JSON
            if (line.contains("\"response\"")) {
                int start = line.indexOf("\"response\":\"") + 12;
                int end = line.indexOf("\"", start);
                if (end == -1) end = line.indexOf("\",", start);
                if (start > 11 && end > start) {
                    String response = line.substring(start, end);
                    // Decodificar caracteres escapados
                    String decoded = response
                        .replace("\\n", "\n")
                        .replace("\\r", "\r")
                        .replace("\\t", "\t")
                        .replace("\\\"", "\"")
                        .replace("\\\\", "\\");
                    callback.onChunkReceived(decoded);
                }
            }
            
            if (line.contains("\"done\":true")) {
                callback.onComplete();
            }
        } catch (Exception e) {
            callback.onError("Error parsing response: " + e.getMessage());
        }
    }

    public String getImageResponse(String imageBase64, String question) throws Exception {
        String requestBody = String.format(
            "{\"model\": \"llava-phi3\", \"prompt\": \"%s\", \"images\": [\"%s\"], \"stream\": false}",
            escapeJsonString(question),
            imageBase64
        );

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create(OLLAMA_BASE_URL + "/api/generate"))
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(requestBody))
            .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() == 200) {
            return extractResponseFromJson(response.body());
        } else {
            throw new RuntimeException("HTTP Error: " + response.statusCode() + " - " + response.body());
        }
    }

    private String extractResponseFromJson(String json) {
        try {
            int start = json.indexOf("\"response\":\"") + 12;
            int end = json.indexOf("\"", start);
            if (start > 11 && end > start) {
                String response = json.substring(start, end);
                // Decodificar correctamente los caracteres escapados
                return response
                    .replace("\\n", "\n")
                    .replace("\\r", "\r")
                    .replace("\\t", "\t")
                    .replace("\\\"", "\"")
                    .replace("\\\\", "\\");
            }
            return "Error: Could not parse response";
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