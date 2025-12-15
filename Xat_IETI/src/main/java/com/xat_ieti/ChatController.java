package com.xat_ieti;

import java.io.File;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.concurrent.CompletableFuture;

import javafx.animation.PauseTransition;
import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Node;
import javafx.scene.SnapshotParameters;
import javafx.scene.control.Alert;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressIndicator;
import javafx.scene.control.ScrollPane;
import javafx.scene.control.TextArea;
import javafx.scene.control.Tooltip;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.image.WritableImage;
import javafx.scene.input.Clipboard;
import javafx.scene.input.ClipboardContent;
import javafx.scene.input.KeyCode;
import javafx.scene.input.KeyEvent;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import javafx.scene.layout.StackPane;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.scene.shape.Circle;
import javafx.stage.FileChooser;
import javafx.util.Duration;

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
        applyStyles();
        
        setTextMode();
        
        makeChatSelectable();
    }

    private void makeChatSelectable() {
        chatContainer.setOnMouseClicked(null);
        
        Platform.runLater(() -> {
            chatContainer.setFocusTraversable(false);
        });
    }

    private void applyStyles() {
        Platform.runLater(() -> {
            if (scrollPane.getScene() != null) {
                try {
                    File cssFile = new File("styles.css");
                    if (cssFile.exists()) {
                        scrollPane.getScene().getStylesheets().add(cssFile.toURI().toString());
                    } else {
                        String embeddedCss = getClass().getResource("/styles.css").toExternalForm();
                        scrollPane.getScene().getStylesheets().add(embeddedCss);
                    }
                } catch (Exception e) {
                    String embeddedCss = """
                        .root {
                            -fx-background-color: #121212;
                        }
                        .scroll-pane {
                            -fx-background: transparent;
                            -fx-background-color: transparent;
                        }
                        .scroll-pane .viewport {
                            -fx-background-color: transparent;
                        }
                        .scroll-bar:vertical .thumb {
                            -fx-background-color: #404040;
                            -fx-background-radius: 10;
                        }
                        #chatContainer {
                            -fx-background-color: #121212;
                        }
                        #topBar {
                            -fx-background-color: #1e1e1e;
                        }
                        #inputBar {
                            -fx-background-color: #1e1e1e;
                        }
                        .button {
                            -fx-background-color: #333333;
                            -fx-background-radius: 8;
                            -fx-text-fill: white;
                        }
                        #sendButton {
                            -fx-background-color: #1976d2;
                        }
                        #stopButton {
                            -fx-background-color: #d32f2f;
                        }
                        .text-area {
                            -fx-background-color: #2d2d2d;
                            -fx-background-radius: 8;
                            -fx-text-fill: white;
                        }
                        .text-area .content {
                            -fx-background-color: #2d2d2d;
                        }
                        #modeLabel {
                            -fx-text-fill: #cccccc;
                            -fx-font-weight: bold;
                        }
                    """;
                    scrollPane.getScene().getStylesheets().add("data:text/css," + embeddedCss);
                }
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
        
        if (!ollamaService.isOllamaRunning()) {
            Platform.runLater(() -> {
                setThinkingIndicator(false);
                showError("Ollama server is not running.\nPlease start it with 'ollama serve' in terminal.");
            });
            return;
        }
        
        currentRequest = CompletableFuture.runAsync(() -> {
            try {
                StringBuilder fullMessage = new StringBuilder();
                ollamaService.streamTextResponse(message, new OllamaService.ResponseCallback() {
                    @Override
                    public void onChunkReceived(String chunk) {
                        fullMessage.append(chunk);
                        Platform.runLater(() -> {
                            setThinkingIndicator(false);
                            updateLastAssistantMessagePreview(fullMessage.toString());
                        });
                    }

                    @Override
                    public void onComplete() {
                        Platform.runLater(() -> {
                            setThinkingIndicator(false);
                            completeLastMessage(fullMessage.toString());
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
                
                Image image = new Image(file.toURI().toString());
                addImageMessage(image, file.getName());
                
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

    private void updateLastAssistantMessagePreview(String text) {
        Platform.runLater(() -> {
            if (messageBubbles.isEmpty()) {
                HBox bubble = createFinalMessageBubble(text, "assistant");
                chatContainer.getChildren().add(bubble);
                messageBubbles.add(bubble);
            } else {
                int lastIndex = messageBubbles.size() - 1;
                HBox lastBubble = messageBubbles.get(lastIndex);
                
                if (lastBubble.getChildren().size() > 0) {
                    VBox bubbleVBox = (VBox) lastBubble.getChildren().get(0);
                    if (bubbleVBox.getChildren().size() > 1) {
                        Node contentNode = bubbleVBox.getChildren().get(1);
                        if (contentNode instanceof Label) {
                            Label content = (Label) contentNode;
                            content.setText(text);
                        }
                    }
                }
            }
            scrollToBottom();
        });
    }

    private void completeLastMessage(String finalMessage) {
        Platform.runLater(() -> {
            if (!messageBubbles.isEmpty()) {
                int lastIndex = messageBubbles.size() - 1;
                if (lastIndex < chatContainer.getChildren().size()) {
                    HBox newBubble = createFinalMessageBubble(finalMessage, "assistant");
                    chatContainer.getChildren().set(lastIndex, newBubble);
                    messageBubbles.set(lastIndex, newBubble);
                }
            }
            currentAssistantMessage = null;
            scrollToBottom();
        });
    }

    private HBox createFinalMessageBubble(String message, String type) {
        HBox container = new HBox();
        container.setPadding(new Insets(5));
        
        VBox bubble = new VBox(5);
        bubble.setMaxWidth(600);
        bubble.setStyle("-fx-background-color: " + 
                    (type.equals("user") ? "#007acc" : "#404040") + 
                    "; -fx-background-radius: 15; -fx-padding: 10;");

        HBox headerBox = new HBox();
        headerBox.setAlignment(Pos.CENTER_LEFT);
        headerBox.setSpacing(8);
        
        if (type.equals("assistant")) {
            ImageView yetiIcon = createYetiIcon();
            Label header = new Label("Assistant");
            header.setStyle("-fx-font-weight: bold; -fx-text-fill: #a0ffa0;");
            
            headerBox.getChildren().addAll(yetiIcon, header);
        } else {
            Label header = new Label("You");
            header.setStyle("-fx-font-weight: bold; -fx-text-fill: #a0d0ff;");
            headerBox.getChildren().add(header);
        }

        if (containsCode(message)) {
            VBox contentBox = createCodeBlock(message, type);
            bubble.getChildren().addAll(headerBox, contentBox);
        } else {
            Label textLabel = new Label(message);
            textLabel.setWrapText(true);
            textLabel.setStyle("-fx-text-fill: white; -fx-font-size: 14px;");
            bubble.getChildren().addAll(headerBox, textLabel);
        }
        
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

    private HBox createMessageBubble(String message, String type) {
        HBox container = new HBox();
        container.setPadding(new Insets(5));
        
        VBox bubble = new VBox(5);
        bubble.setMaxWidth(600);
        bubble.setStyle("-fx-background-color: " + 
                    (type.equals("user") ? "#007acc" : "#404040") + 
                    "; -fx-background-radius: 15; -fx-padding: 10;");

        HBox headerBox = new HBox();
        headerBox.setAlignment(Pos.CENTER_LEFT);
        headerBox.setSpacing(8);
        
        if (type.equals("assistant")) {
            ImageView yetiIcon = createYetiIcon();
            Label header = new Label("Assistant");
            header.setStyle("-fx-font-weight: bold; -fx-text-fill: #a0ffa0;");
            
            headerBox.getChildren().addAll(yetiIcon, header);
        } else {
            Label header = new Label("You");
            header.setStyle("-fx-font-weight: bold; -fx-text-fill: #a0d0ff;");
            headerBox.getChildren().add(header);
        }

        if (containsCode(message)) {
            VBox contentBox = createCodeBlock(message, type);
            bubble.getChildren().addAll(headerBox, contentBox);
        } else {
            Label textLabel = new Label(message);
            textLabel.setWrapText(true);
            textLabel.setStyle("-fx-text-fill: white; -fx-font-size: 14px;");
            bubble.getChildren().addAll(headerBox, textLabel);
        }
        
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

    private ImageView createYetiIcon() {
        try {
            String imagePath = "/assets/ieti.jpg";
            java.net.URL imageUrl = getClass().getResource(imagePath);
            
            if (imageUrl != null) {
                Image yetiImage = new Image(imageUrl.toExternalForm());
                ImageView yetiIcon = new ImageView(yetiImage);
                yetiIcon.setFitWidth(20);
                yetiIcon.setFitHeight(20);
                yetiIcon.setPreserveRatio(true);
                yetiIcon.setStyle("-fx-effect: dropshadow(gaussian, rgba(0,0,0,0.3), 2, 0, 1, 1);");
                return yetiIcon;
            } else {
                System.out.println("❌ No se pudo encontrar la imagen en: " + imagePath);
                try {
                    java.nio.file.Path assetsPath = java.nio.file.Paths.get("src/main/resources/assets");
                    if (java.nio.file.Files.exists(assetsPath)) {
                        System.out.println("Archivos en assets:");
                        java.nio.file.Files.list(assetsPath).forEach(file -> 
                            System.out.println("  - " + file.getFileName()));
                    }
                } catch (Exception e) {
                    System.out.println("No se pudo listar archivos: " + e.getMessage());
                }
                return createPlaceholderYeti();
            }
        } catch (Exception e) {
            System.err.println("Error cargando la imagen del yeti: " + e.getMessage());
            return createPlaceholderYeti();
        }
    }

    private ImageView createPlaceholderYeti() {
        Circle placeholder = new Circle(10);
        placeholder.setFill(Color.LIGHTBLUE);
        
        WritableImage image = new WritableImage(20, 20);
        SnapshotParameters params = new SnapshotParameters();
        params.setFill(Color.TRANSPARENT);
        
        StackPane tempPane = new StackPane(placeholder);
        tempPane.snapshot(params, image);
        
        ImageView placeholderIcon = new ImageView(image);
        placeholderIcon.setFitWidth(20);
        placeholderIcon.setFitHeight(20);
        
        return placeholderIcon;
    }

    private boolean containsCode(String message) {
        return message.contains("```") || 
            message.contains("\\u003c") ||
            message.matches(".*(public|class|function|def|import|package).*") ||
            message.contains("<html") ||
            message.contains("DOCTYPE");
    }

    private VBox createCodeBlock(String message, String type) {
        VBox codeContainer = new VBox(5);
        codeContainer.getStyleClass().add("code-block");
        
        HBox headerBox = new HBox();
        headerBox.setAlignment(Pos.CENTER_LEFT);
        headerBox.setSpacing(10);
        
        Label languageLabel = new Label(detectLanguage(message));
        languageLabel.getStyleClass().add("code-header");
        
        Button copyButton = new Button("Copy");
        copyButton.getStyleClass().add("copy-button");
        copyButton.setOnAction(e -> copyToClipboard(extractCodeContent(message)));
        
        HBox.setHgrow(languageLabel, Priority.ALWAYS);
        headerBox.getChildren().addAll(languageLabel, copyButton);
        
        String codeContent = extractCodeContent(message);
        TextArea codeArea = new TextArea(codeContent);
        codeArea.setEditable(false);
        codeArea.setWrapText(true);
        codeArea.setStyle("-fx-control-inner-background: #1e1e1e; " +
                        "-fx-background-color: #1e1e1e; " +
                        "-fx-text-fill: #d4d4d4; " +
                        "-fx-font-family: 'Consolas', 'Monaco', 'Courier New', monospace; " +
                        "-fx-font-size: 12px; " +
                        "-fx-border-color: #404040; " +
                        "-fx-border-radius: 4;");
        
        int lineCount = codeContent.split("\n").length;
        codeArea.setPrefRowCount(Math.min(Math.max(lineCount, 3), 15));
        
        codeContainer.getChildren().addAll(headerBox, codeArea);
        return codeContainer;
    }

    private String detectLanguage(String message) {
        if (message.contains("html") || message.contains("\\u003c")) return "HTML";
        if (message.contains("public class")) return "Java";
        if (message.contains("def ")) return "Python";
        if (message.contains("function")) return "JavaScript";
        if (message.contains("<?php")) return "PHP";
        return "Code";
    }

    private String extractCodeContent(String message) {
        String cleaned = message
            .replace("\\u003c", "<")
            .replace("\\u003e", ">")
            .replace("\\\"", "\"")
            .replace("\\\\", "\\")
            .replace("\\n", "\n")
            .replace("\\t", "\t");
        
        if (cleaned.contains("```")) {
            String[] parts = cleaned.split("```");
            if (parts.length >= 2) {
                String code = parts[1].trim();
                if (code.contains("\n")) {
                    int firstNewline = code.indexOf("\n");
                    if (firstNewline > 0) {
                        code = code.substring(firstNewline + 1);
                    }
                }
                return code.trim();
            }
        }
        
        return cleaned.trim();
    }

    private int calculateRowCount(String code) {
        int lines = code.split("\n").length;
        return Math.min(Math.max(lines, 3), 15);
    }

    private void copyToClipboard(String text) {
        Clipboard clipboard = Clipboard.getSystemClipboard();
        ClipboardContent content = new ClipboardContent();
        content.putString(text);
        clipboard.setContent(content);
        
        showNotification("Code copied to clipboard!");
    }

    private void showNotification(String message) {
        Platform.runLater(() -> {
            Tooltip tooltip = new Tooltip(message);
            tooltip.setAutoHide(true);
            tooltip.show(sendButton.getScene().getWindow());
            
            PauseTransition delay = new PauseTransition(Duration.seconds(2));
            delay.setOnFinished(e -> tooltip.hide());
            delay.play();
        });
    }

    @FXML
    private void handleChatClick(MouseEvent event) {
        event.consume();
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