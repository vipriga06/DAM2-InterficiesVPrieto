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
        // Aplicar estilos CSS
        applyStyles();
        
        // Inicializar el modo de texto
        setTextMode();
        
        // Hacer el chatContainer seleccionable
        makeChatSelectable();
    }

    private void makeChatSelectable() {
        // Permitir selección de texto en todo el chat
        chatContainer.setOnMouseClicked(null); // Elimina cualquier handler que impida la selección
        
        // Asegurar que los elementos de texto sean focusable
        Platform.runLater(() -> {
            chatContainer.setFocusTraversable(false);
        });
    }

    private void applyStyles() {
        Platform.runLater(() -> {
            if (scrollPane.getScene() != null) {
                // Cargar el archivo CSS externo
                try {
                    File cssFile = new File("styles.css");
                    if (cssFile.exists()) {
                        scrollPane.getScene().getStylesheets().add(cssFile.toURI().toString());
                    } else {
                        // Fallback: usar CSS embebido
                        String embeddedCss = getClass().getResource("/styles.css").toExternalForm();
                        scrollPane.getScene().getStylesheets().add(embeddedCss);
                    }
                } catch (Exception e) {
                    // CSS embebido como fallback
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
        
        // Verificar conexión con Ollama
        if (!ollamaService.isOllamaRunning()) {
            Platform.runLater(() -> {
                setThinkingIndicator(false);
                showError("Ollama server is not running.\nPlease start it with 'ollama serve' in terminal.");
            });
            return;
        }
        
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
                
                // Verificar si el último mensaje contiene código
                if (containsCode(currentAssistantMessage)) {
                    // Recrear la burbuja con el código completo
                    chatContainer.getChildren().remove(lastBubble);
                    HBox newBubble = createMessageBubble(currentAssistantMessage, "assistant");
                    chatContainer.getChildren().add(newBubble);
                    messageBubbles.set(messageBubbles.size() - 1, newBubble);
                } else {
                    // Actualizar texto normal
                    Node contentNode = (Node) bubbleVBox.getChildren().get(1);
                    if (contentNode instanceof TextArea) {
                        TextArea content = (TextArea) contentNode;
                        content.setText(currentAssistantMessage);
                        
                        // Auto-ajustar altura
                        int lines = currentAssistantMessage.split("\n").length;
                        content.setPrefRowCount(Math.min(Math.max(lines, 1), 10));
                    }
                }
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
        bubble.setMaxWidth(600);
        bubble.setStyle("-fx-background-color: " + 
                    (type.equals("user") ? "#007acc" : "#404040") + 
                    "; -fx-background-radius: 15; -fx-padding: 10;");

        // Header con imagen para assistant o solo texto para user
        HBox headerBox = new HBox();
        headerBox.setAlignment(Pos.CENTER_LEFT);
        headerBox.setSpacing(8);
        
        if (type.equals("assistant")) {
            // Añadir imagen de yeti para el assistant
            ImageView yetiIcon = createYetiIcon();
            Label header = new Label("Assistant");
            header.setStyle("-fx-font-weight: bold; -fx-text-fill: #a0ffa0;");
            
            headerBox.getChildren().addAll(yetiIcon, header);
        } else {
            // Solo texto para el usuario
            Label header = new Label("You");
            header.setStyle("-fx-font-weight: bold; -fx-text-fill: #a0d0ff;");
            headerBox.getChildren().add(header);
        }

        // Detectar si el mensaje contiene código
        if (containsCode(message)) {
            VBox contentBox = createCodeBlock(message, type);
            bubble.getChildren().addAll(headerBox, contentBox);
        } else {
            TextArea textArea = createSelectableTextArea(message);
            bubble.getChildren().addAll(headerBox, textArea);
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
            // Método más directo para cargar la imagen
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
                // Verificar qué archivos hay en assets
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
        // Crear un círculo azul como placeholder si no hay imagen
        Circle placeholder = new Circle(10);
        placeholder.setFill(Color.LIGHTBLUE);
        
        // Convertir el círculo a ImageView
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

    private TextArea createSelectableTextArea(String text) {
        TextArea textArea = new TextArea(text);
        textArea.setEditable(false);
        textArea.setWrapText(true);
        textArea.setPrefRowCount(1);
        textArea.setStyle("-fx-control-inner-background: transparent; " +
                        "-fx-background-color: transparent; " +
                        "-fx-border-color: transparent; " +
                        "-fx-text-fill: white; " +
                        "-fx-font-size: 14px; " +
                        "-fx-padding: 0;");
        
        // Auto-ajustar altura
        textArea.textProperty().addListener((observable, oldValue, newValue) -> {
            int lines = newValue.split("\n").length;
            textArea.setPrefRowCount(Math.min(Math.max(lines, 1), 10));
        });
        
        return textArea;
    }

    private boolean containsCode(String message) {
        // Detectar patrones comunes de código
        return message.contains("```") || 
            message.contains("\\u003c") ||
            message.matches(".*(public|class|function|def|import|package).*") ||
            message.contains("<html") ||
            message.contains("DOCTYPE");
    }

    private VBox createCodeBlock(String message, String type) {
        VBox codeContainer = new VBox(5);
        codeContainer.getStyleClass().add("code-block");
        
        // Header con lenguaje y botón de copiar
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
        
        // Área de texto para el código (ya es seleccionable por defecto)
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
        
        // Auto-ajustar altura según el contenido
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
        // Limpiar el código de caracteres escapados y formato
        String cleaned = message
            .replace("\\u003c", "<")
            .replace("\\u003e", ">")
            .replace("\\\"", "\"")
            .replace("\\\\", "\\")
            .replace("\\n", "\n")
            .replace("\\t", "\t");
        
        // Extraer código entre ``` si existe
        if (cleaned.contains("```")) {
            String[] parts = cleaned.split("```");
            if (parts.length >= 2) {
                // Remover el lenguaje si está especificado
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
        return Math.min(Math.max(lines, 3), 15); // Mínimo 3, máximo 15 líneas
    }

    private void copyToClipboard(String text) {
        Clipboard clipboard = Clipboard.getSystemClipboard();
        ClipboardContent content = new ClipboardContent();
        content.putString(text);
        clipboard.setContent(content);
        
        // Mostrar confirmación
        showNotification("Code copied to clipboard!");
    }

    private void showNotification(String message) {
        Platform.runLater(() -> {
            Tooltip tooltip = new Tooltip(message);
            tooltip.setAutoHide(true);
            tooltip.show(sendButton.getScene().getWindow());
            
            // Auto-ocultar después de 2 segundos
            PauseTransition delay = new PauseTransition(Duration.seconds(2));
            delay.setOnFinished(e -> tooltip.hide());
            delay.play();
        });
    }

    @FXML
    private void handleChatClick(MouseEvent event) {
        // Permite hacer clic en el área del chat sin afectar la selección de texto
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