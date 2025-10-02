package com.xat_ieti;

import java.io.File;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.concurrent.CompletableFuture;

import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.control.Alert;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressIndicator;
import javafx.scene.control.ScrollPane;
import javafx.scene.control.TextArea;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.KeyCode;
import javafx.scene.input.KeyEvent;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import javafx.scene.layout.StackPane;
import javafx.scene.layout.VBox;
import javafx.scene.text.Font;
import javafx.stage.FileChooser;

public class ChatController {
    
    @FXML private StackPane rootPane;
    @FXML private BorderPane chatBorderPane;
    @FXML private VBox chatContainer;
    @FXML private ScrollPane scrollPane;
    @FXML private TextArea messageInput;
    @FXML private Button sendButton;
    @FXML private Button uploadImageButton;
    @FXML private Button stopButton;
    @FXML private Button textModeButton;
    @FXML private Button imageModeButton;
    @FXML private ProgressIndicator thinkingIndicator;
    @FXML private Label modeLabel;
    
    private final OllamaService ollamaService;
    private CompletableFuture<Void> currentRequest;
    private boolean isImageMode = false;
    private String currentImageBase64;
    
    private final List<HBox> messageBubbles;
    private String currentAssistantMessage;

    public ChatController() {
        this.ollamaService = new OllamaService();
        this.messageBubbles = new ArrayList<>();
    }

    @FXML
    private void initialize() {
        // Aplicar estilos CSS
        applyStyles();
        
        // Inicializar el modo de texto
        setTextMode();
    }

    private void applyStyles() {
        // Esperar a que la escena esté disponible
        Platform.runLater(() -> {
            if (scrollPane.getScene() != null) {
                String css = """
                    .scroll-pane {
                        -fx-background: transparent;
                        -fx-background-color: transparent;
                    }
                    .scroll-pane .viewport {
                        -fx-background-color: transparent;
                    }
                    .scroll-bar:vertical {
                        -fx-background-color: transparent;
                    }
                    .scroll-bar:vertical .track {
                        -fx-background-color: transparent;
                    }
                    .scroll-bar:vertical .thumb {
                        -fx-background-color: #505050;
                    }
                """;
                scrollPane.getScene().getStylesheets().add("data:text/css," + css);
            }
        });
    }

    @FXML
    private void handleKeyPressed(KeyEvent event) {
        if (event.getCode() == KeyCode.ENTER && !event.isShiftDown()) {
            event.consume();
            sendTextMessage();
        }
    }

    @FXML
    private void sendTextMessage() {
        String message = messageInput.getText().trim();
        if (message.isEmpty()) return;

        addUserMessage(message);
        messageInput.clear();
        setThinkingIndicator(true);

        if (isImageMode && currentImageBase64 != null) {
            processImageWithQuestion(message);
        } else {
            processTextMessage(message);
        }
    }

    private void processTextMessage(String message) {
        stopCurrentRequest();
        
        currentRequest = CompletableFuture.runAsync(() -> {
            try {
                ollamaService.streamTextResponse(message, new OllamaService.ResponseCallback() {
                    @Override
                    public void onChunkReceived(String chunk) {
                        Platform.runLater(() -> appendToLastAssistantMessage(chunk));
                    }

                    @Override
                    public void onComplete() {
                        Platform.runLater(() -> {
                            setThinkingIndicator(false);
                            completeLastMessage();
                        });
                    }

                    @Override
                    public void onError(String error) {
                        Platform.runLater(() -> {
                            setThinkingIndicator(false);
                            showError("Error processing text: " + error);
                        });
                    }
                });
            } catch (Exception e) {
                Platform.runLater(() -> {
                    setThinkingIndicator(false);
                    showError("Error: " + e.getMessage());
                });
            }
        });
    }

    private void processImageWithQuestion(String question) {
        stopCurrentRequest();
        
        currentRequest = CompletableFuture.runAsync(() -> {
            try {
                String response = ollamaService.getImageResponse(currentImageBase64, question);
                Platform.runLater(() -> {
                    addAssistantMessage(response);
                    setThinkingIndicator(false);
                });
            } catch (Exception e) {
                Platform.runLater(() -> {
                    setThinkingIndicator(false);
                    showError("Error processing image: " + e.getMessage());
                });
            }
        });
    }

    @FXML
    private void uploadImage() {
        FileChooser fileChooser = new FileChooser();
        fileChooser.setTitle("Select Image");
        fileChooser.getExtensionFilters().addAll(
            new FileChooser.ExtensionFilter("Image Files", "*.png", "*.jpg", "*.jpeg", "*.gif")
        );

        File file = fileChooser.showOpenDialog(uploadImageButton.getScene().getWindow());
        if (file != null) {
            try {
                byte[] fileContent = Files.readAllBytes(file.toPath());
                currentImageBase64 = Base64.getEncoder().encodeToString(fileContent);
                
                // Mostrar imagen en el chat
                Image image = new Image(file.toURI().toString());
                addImageMessage(image, file.getName());
                
                // Cambiar a modo imagen automáticamente
                setImageMode();
                
            } catch (Exception e) {
                showError("Error loading image: " + e.getMessage());
            }
        }
    }

    @FXML
    private void setTextMode() {
        isImageMode = false;
        setModeIndicator("Text Mode");
        messageInput.setPromptText("Type your message...");
    }

    @FXML
    private void setImageMode() {
        if (currentImageBase64 != null) {
            isImageMode = true;
            setModeIndicator("Image Mode");
            messageInput.setPromptText("Ask about the image...");
        } else {
            showError("Please upload an image first");
        }
    }

    @FXML
    private void stopCurrentRequest() {
        if (currentRequest != null && !currentRequest.isDone()) {
            currentRequest.cancel(true);
            setThinkingIndicator(false);
        }
    }

    private void addUserMessage(String message) {
        Platform.runLater(() -> {
            HBox bubble = createMessageBubble(message, "user");
            chatContainer.getChildren().add(bubble);
            scrollToBottom();
        });
    }

    private void addAssistantMessage(String message) {
        Platform.runLater(() -> {
            HBox bubble = createMessageBubble(message, "assistant");
            chatContainer.getChildren().add(bubble);
            scrollToBottom();
        });
    }

    private void addImageMessage(Image image, String filename) {
        Platform.runLater(() -> {
            HBox container = new HBox();
            container.setAlignment(Pos.CENTER_RIGHT);
            container.setPadding(new Insets(5));

            VBox bubble = new VBox(5);
            bubble.setStyle("-fx-background-color: #505050; -fx-background-radius: 15; -fx-padding: 10;");
            bubble.setMaxWidth(300);

            ImageView imageView = new ImageView(image);
            imageView.setFitWidth(250);
            imageView.setFitHeight(200);
            imageView.setPreserveRatio(true);

            Label label = new Label("📷 " + filename);
            label.setStyle("-fx-text-fill: white;");

            bubble.getChildren().addAll(imageView, label);
            container.getChildren().add(bubble);

            chatContainer.getChildren().add(container);
            scrollToBottom();
        });
    }

    private void appendToLastAssistantMessage(String text) {
        Platform.runLater(() -> {
            if (currentAssistantMessage == null) {
                currentAssistantMessage = text;
                HBox bubble = createMessageBubble(text, "assistant");
                chatContainer.getChildren().add(bubble);
                messageBubbles.add(bubble);
            } else {
                currentAssistantMessage += text;
                HBox lastBubble = messageBubbles.get(messageBubbles.size() - 1);
                VBox bubbleVBox = (VBox) lastBubble.getChildren().get(0);
                Label content = (Label) bubbleVBox.getChildren().get(1);
                content.setText(currentAssistantMessage);
            }
            scrollToBottom();
        });
    }

    private void completeLastMessage() {
        currentAssistantMessage = null;
    }

    private HBox createMessageBubble(String message, String type) {
        HBox container = new HBox();
        container.setPadding(new Insets(5));
        
        VBox bubble = new VBox(5);
        bubble.setMaxWidth(400);
        bubble.setStyle("-fx-background-color: " + 
                       (type.equals("user") ? "#007acc" : "#404040") + 
                       "; -fx-background-radius: 15; -fx-padding: 10;");

        Label header = new Label(type.equals("user") ? "You" : "Assistant");
        header.setStyle("-fx-font-weight: bold; -fx-text-fill: " + 
                       (type.equals("user") ? "#a0d0ff" : "#a0ffa0") + ";");

        Label content = new Label(message);
        content.setWrapText(true);
        content.setFont(Font.font(14));
        content.setStyle("-fx-text-fill: white;");

        bubble.getChildren().addAll(header, content);
        
        if (type.equals("user")) {
            container.setAlignment(Pos.CENTER_RIGHT);
            HBox.setHgrow(container, Priority.ALWAYS);
        } else {
            container.setAlignment(Pos.CENTER_LEFT);
            HBox.setHgrow(container, Priority.ALWAYS);
        }
        
        container.getChildren().add(bubble);
        return container;
    }

    private void scrollToBottom() {
        Platform.runLater(() -> scrollPane.setVvalue(1.0));
    }

    private void setThinkingIndicator(boolean thinking) {
        thinkingIndicator.setVisible(thinking);
    }

    private void setModeIndicator(String mode) {
        modeLabel.setText(mode);
    }

    private void showError(String message) {
        Platform.runLater(() -> {
            Alert alert = new Alert(Alert.AlertType.ERROR);
            alert.setTitle("Error");
            alert.setHeaderText(null);
            alert.setContentText(message);
            alert.showAndWait();
        });
    }
}