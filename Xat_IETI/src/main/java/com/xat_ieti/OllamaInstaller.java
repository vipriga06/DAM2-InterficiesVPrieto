package com.xat_ieti;

import java.awt.Desktop;
import java.io.IOException;
import java.net.URI;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;

import javafx.application.Platform;
import javafx.scene.control.Alert;
import javafx.scene.control.ButtonType;
import javafx.scene.control.Hyperlink;
import javafx.scene.layout.Region;
import javafx.scene.text.Text;
import javafx.scene.text.TextFlow;

public class OllamaInstaller {

    private static final String OLLAMA_DOWNLOAD_URL = "https://ollama.com/download";

    public static boolean isOllamaInstalled() {
        try {
            ProcessBuilder pb;
            String os = System.getProperty("os.name").toLowerCase();

            if (os.contains("win")) {
                pb = new ProcessBuilder("cmd", "/c", "where ollama");
            } else {
                pb = new ProcessBuilder("/bin/sh", "-c", "which ollama");
            }

            Process process = pb.start();
            int exitCode = process.waitFor();
            return exitCode == 0;

        } catch (IOException | InterruptedException e) {
            System.err.println("Error checking Ollama installation: " + e.getMessage());
            return false;
        }
    }

    public static CompletableFuture<Boolean> promptOllamaInstallation() {
        CompletableFuture<Boolean> result = new CompletableFuture<>();

        Platform.runLater(() -> {
            Alert alert = new Alert(Alert.AlertType.CONFIRMATION);
            alert.setTitle("Ollama Not Found");
            alert.setHeaderText("Ollama server is not installed or not found in your system's PATH.");
            
            TextFlow content = new TextFlow(
                new Text("To use this application, you need to have Ollama installed. Please download and install it from the official website: "),
                createHyperlink(OLLAMA_DOWNLOAD_URL, "ollama.com/download"),
                new Text("\n\nAfter installation, please restart this application.")
            );
            
            alert.getDialogPane().setContent(content);
            alert.getDialogPane().setMinHeight(Region.USE_PREF_SIZE);

            ButtonType downloadButton = new ButtonType("Go to Download Page");
            ButtonType cancelButton = new ButtonType("Exit Application");

            alert.getButtonTypes().setAll(downloadButton, cancelButton);

            Optional<ButtonType> response = alert.showAndWait();

            if (response.isPresent() && response.get() == downloadButton) {
                openWebpage(OLLAMA_DOWNLOAD_URL);
                result.complete(true);
            } else {
                result.complete(false);
            }
        });
        return result;
    }

    private static Hyperlink createHyperlink(String url, String text) {
        Hyperlink link = new Hyperlink(text);
        link.setOnAction(e -> openWebpage(url));
        return link;
    }

    private static void openWebpage(String url) {
        try {
            if (Desktop.isDesktopSupported() && Desktop.getDesktop().isSupported(Desktop.Action.BROWSE)) {
                Desktop.getDesktop().browse(new URI(url));
            } else {
                System.out.println("Desktop API not supported. Please open " + url + " manually.");
            }
        } catch (Exception e) {
            System.err.println("Error opening webpage: " + e.getMessage());
        }
    }
}
