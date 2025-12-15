package com.xat_ieti;

import com.utils.UtilsViews;

import javafx.application.Application;
import javafx.application.Platform;
import javafx.scene.Scene;
import javafx.scene.control.Alert;
import javafx.stage.Stage;

public class Main extends Application {
    
    private static Process ollamaProcess;

    @Override
    public void start(Stage primaryStage) throws Exception {
        if (!OllamaInstaller.isOllamaInstalled()) {
            OllamaInstaller.promptOllamaInstallation().thenAccept(shouldExit -> {
                if (shouldExit) {
                    Platform.exit(); 
                } else {
                    Platform.exit();
                }
            });
            return;
        }

        System.out.println("Ollama is installed. Proceeding with application startup.");

        startOllamaServer();
        
        Thread.sleep(2000); 
        
        UtilsViews.addView(Main.class, "chatView", "/assets/ChatView.fxml");
        
        Scene scene = new Scene(UtilsViews.parentContainer, 800, 600);
        
        primaryStage.setTitle("Xat IETI");
        primaryStage.setScene(scene);
        primaryStage.setMinWidth(800);
        primaryStage.setMinHeight(600);
        
        primaryStage.setOnCloseRequest(event -> stopOllamaServer());
        
        primaryStage.show();
        
        UtilsViews.setView("chatView");
    }

    private void startOllamaServer() {
        try {
            System.out.println("Starting Ollama server...");
            
            String os = System.getProperty("os.name").toLowerCase();
            ProcessBuilder processBuilder;
            
            if (os.contains("win")) {
                processBuilder = new ProcessBuilder("cmd", "/c", "ollama", "serve");
            } else if (os.contains("mac")) {
                processBuilder = new ProcessBuilder("/bin/sh", "-c", "ollama serve");
            } else {
                processBuilder = new ProcessBuilder("/bin/bash", "-c", "ollama serve");
            }
            
            processBuilder.redirectErrorStream(true);
            
            ollamaProcess = processBuilder.start();
            
            System.out.println("Ollama server started successfully");
            
        } catch (Exception e) {
            System.err.println("Error starting Ollama server: " + e.getMessage());
            System.err.println("Please make sure Ollama is installed and in your PATH");
            Platform.runLater(() -> {
                Alert alert = new Alert(Alert.AlertType.ERROR);
                alert.setTitle("Ollama Server Error");
                alert.setHeaderText("Failed to start Ollama server.");
                alert.setContentText("An error occurred while trying to start the Ollama server. Please check if Ollama is running correctly or if there are any conflicts.\n\nError: " + e.getMessage());
                alert.showAndWait();
                Platform.exit();
            });
        }
    }

    private void stopOllamaServer() {
        if (ollamaProcess != null && ollamaProcess.isAlive()) {
            System.out.println("Stopping Ollama server...");
            ollamaProcess.destroy();
            try {
                ollamaProcess.waitFor();
                System.out.println("Ollama server stopped");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public void stop() {
        stopOllamaServer();
    }

    public static void main(String[] args) {
        launch(args);
    }
}
