package com.xat_ieti;

import com.utils.UtilsViews;

import javafx.application.Application;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class Main extends Application {
    
    private static Process ollamaProcess;

    @Override
    public void start(Stage primaryStage) throws Exception {
        // Iniciar Ollama serve
        startOllamaServer();
        
        // Esperar un momento para que Ollama se inicie
        Thread.sleep(2000);
        
        // Añadir la vista del chat al sistema de gestión de vistas
        UtilsViews.addView(Main.class, "chatView", "/assets/ChatView.fxml");
        
        // Crear la escena con el contenedor principal de UtilsViews
        Scene scene = new Scene(UtilsViews.parentContainer, 800, 600);
        
        // Configurar y mostrar la ventana
        primaryStage.setTitle("Xat IETI");
        primaryStage.setScene(scene);
        primaryStage.setMinWidth(800);
        primaryStage.setMinHeight(600);
        
        // Cerrar Ollama cuando se cierre la aplicación
        primaryStage.setOnCloseRequest(event -> stopOllamaServer());
        
        primaryStage.show();
        
        // Establecer la vista del chat como activa
        UtilsViews.setView("chatView");
    }

    private void startOllamaServer() {
        try {
            System.out.println("Starting Ollama server...");
            
            // Detectar sistema operativo
            String os = System.getProperty("os.name").toLowerCase();
            ProcessBuilder processBuilder;
            
            if (os.contains("win")) {
                // Windows
                processBuilder = new ProcessBuilder("cmd", "/c", "ollama", "serve");
            } else if (os.contains("mac")) {
                // macOS
                processBuilder = new ProcessBuilder("/bin/sh", "-c", "ollama serve");
            } else {
                // Linux
                processBuilder = new ProcessBuilder("/bin/bash", "-c", "ollama serve");
            }
            
            // Redirigir salida para ver logs (opcional)
            processBuilder.redirectErrorStream(true);
            
            // Iniciar el proceso
            ollamaProcess = processBuilder.start();
            
            System.out.println("Ollama server started successfully");
            
        } catch (Exception e) {
            System.err.println("Error starting Ollama server: " + e.getMessage());
            System.err.println("Please make sure Ollama is installed and in your PATH");
            e.printStackTrace();
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