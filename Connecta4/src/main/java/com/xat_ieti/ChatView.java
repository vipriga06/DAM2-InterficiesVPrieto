package com.xat_ieti;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

import javafx.application.Platform;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressIndicator;
import javafx.scene.control.ScrollPane;
import javafx.scene.control.Separator;
import javafx.scene.control.TextArea;
import javafx.scene.control.Tooltip;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import javafx.scene.layout.VBox;
import javafx.scene.text.Font;
import javafx.scene.text.FontWeight;

public class ChatView {
    private final Scene scene;
    private final VBox chatContainer;
    private final ScrollPane scrollPane;
    private final TextArea messageInput;
    private final Button sendButton;
    private final Button uploadImageButton;
    private final Button stopButton;
    private final Button textModeButton;
    private final Button imageModeButton;
    private final ProgressIndicator thinkingIndicator;
    private final Label modeLabel;
    private final VBox statusContainer; // Nuevo: contenedor de estado
    private final Label statusLabel; // Nuevo: etiqueta de estado
    private final Label connectionLabel; // Nuevo: etiqueta de conexión
    
    private final List<HBox> messageBubbles;
    private String currentAssistantMessage;

    public ChatView() {
        messageBubbles = new ArrayList<>();

        // Contenedor principal
        BorderPane root = new BorderPane();
        root.setPrefSize(800, 600);

        // Crear componentes de la barra superior
        modeLabel = new Label("Text Mode");
        modeLabel.setStyle("-fx-text-fill: white; -fx-font-weight: bold;");

        textModeButton = new Button("Text Mode");
        imageModeButton = new Button("Image Mode");

        stopButton = new Button("Stop");
        stopButton.setStyle("-fx-background-color: #ff4444; -fx-text-fill: white;");

        thinkingIndicator = new ProgressIndicator();
        thinkingIndicator.setVisible(false);
        thinkingIndicator.setPrefSize(20, 20);

        // Barra superior con controles de modo
        HBox topBar = createTopBar();
        root.setTop(topBar);

        // Crear contenedor principal de chat con estado
        VBox mainChatContainer = new VBox();
        mainChatContainer.setStyle("-fx-background-color: #1e1e1e;");
        
        // Crear contenedor de estado del modelo
        statusContainer = createStatusContainer();
        
        // Área de chat
        chatContainer = createChatContainer();
        
        // Agregar estado y chat al contenedor principal
        mainChatContainer.getChildren().addAll(statusContainer, chatContainer);
        VBox.setVgrow(chatContainer, Priority.ALWAYS);
        
        scrollPane = new ScrollPane(mainChatContainer);
        scrollPane.setFitToWidth(true);
        scrollPane.setStyle("-fx-background: transparent; -fx-background-color: transparent;");
        root.setCenter(scrollPane);

        // Crear componentes de la barra de entrada
        uploadImageButton = new Button("📷");
        uploadImageButton.setTooltip(new Tooltip("Upload Image"));

        messageInput = new TextArea();
        messageInput.setPrefRowCount(2);
        messageInput.setWrapText(true);
        messageInput.setPromptText("Type your message...");
        HBox.setHgrow(messageInput, Priority.ALWAYS);

        sendButton = new Button("Send");
        sendButton.setDefaultButton(true);

        // Barra inferior de entrada
        HBox inputBar = createInputBar();
        root.setBottom(inputBar);

        // Inicializar labels de estado
        statusLabel = (Label) ((VBox) statusContainer.getChildren().get(0)).getChildren().get(1);
        connectionLabel = (Label) ((VBox) statusContainer.getChildren().get(0)).getChildren().get(2);

        scene = new Scene(root);
        applyStyles();
        
        // Inicializar estado
        updateModelStatus("Initializing...", false);
    }

    private VBox createStatusContainer() {
        VBox container = new VBox(5);
        container.setPadding(new Insets(15, 10, 15, 10));
        container.setAlignment(Pos.CENTER);
        container.setStyle("-fx-background-color: #252525; -fx-border-color: #404040; -fx-border-width: 0 0 1 0;");
        
        VBox statusBox = new VBox(5);
        statusBox.setAlignment(Pos.CENTER);
        
        Label titleLabel = new Label("🤖 Model Status");
        titleLabel.setFont(Font.font("System", FontWeight.BOLD, 14));
        titleLabel.setStyle("-fx-text-fill: #00d4ff;");
        
        Label status = new Label("Ready");
        status.setFont(Font.font("System", 12));
        status.setStyle("-fx-text-fill: #a0a0a0;");
        
        Label connection = new Label("● Disconnected");
        connection.setFont(Font.font("System", 11));
        connection.setStyle("-fx-text-fill: #ff4444;");
        
        statusBox.getChildren().addAll(titleLabel, status, connection);
        container.getChildren().add(statusBox);
        
        return container;
    }

    private HBox createTopBar() {
        HBox topBar = new HBox(10);
        topBar.setPadding(new Insets(10));
        topBar.setAlignment(Pos.CENTER_LEFT);
        topBar.setStyle("-fx-background-color: #2b2b2b;");

        topBar.getChildren().addAll(modeLabel, textModeButton, imageModeButton,
                                   new Separator(), stopButton, thinkingIndicator);
        return topBar;
    }

    private VBox createChatContainer() {
        VBox container = new VBox();
        container.setPadding(new Insets(10));
        container.setSpacing(10);
        container.setStyle("-fx-background-color: #1e1e1e;");
        return container;
    }

    private HBox createInputBar() {
        HBox inputBar = new HBox(10);
        inputBar.setPadding(new Insets(10));
        inputBar.setStyle("-fx-background-color: #3c3c3c;");

        inputBar.getChildren().addAll(uploadImageButton, messageInput, sendButton);
        return inputBar;
    }

    private void applyStyles() {
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
        scene.getStylesheets().add("data:text/css," + css);
    }

    // Nuevo método para actualizar el estado del modelo
    public void updateModelStatus(String status, boolean connected) {
        Platform.runLater(() -> {
            statusLabel.setText(status);
            
            String connectionText = connected ? "● Connected" : "● Disconnected";
            String connectionColor = connected ? "#44ff44" : "#ff4444";
            connectionLabel.setText(connectionText);
            connectionLabel.setStyle("-fx-text-fill: " + connectionColor + ";");
            
            // Agregar timestamp
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH:mm:ss");
            String timestamp = LocalDateTime.now().format(formatter);
            statusLabel.setText(status + " [" + timestamp + "]");
        });
    }

    // Nuevo método para actualizar estado durante procesamiento
    public void updateProcessingStatus(String message) {
        updateModelStatus("Processing: " + message, true);
    }

    // Nuevo método para actualizar estado cuando está listo
    public void updateReadyStatus(String modelName) {
        updateModelStatus("Ready - Model: " + modelName, true);
    }

    // Nuevo método para actualizar estado de error
    public void updateErrorStatus(String error) {
        updateModelStatus("Error: " + error, false);
    }

    public void addUserMessage(String message) {
        Platform.runLater(() -> {
            HBox bubble = createMessageBubble(message, "user");
            chatContainer.getChildren().add(bubble);
            scrollToBottom();
            updateProcessingStatus("Generating response...");
        });
    }

    public void addAssistantMessage(String message) {
        Platform.runLater(() -> {
            HBox bubble = createMessageBubble(message, "assistant");
            chatContainer.getChildren().add(bubble);
            scrollToBottom();
        });
    }

    public void addImageMessage(Image image, String filename) {
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
            updateProcessingStatus("Analyzing image...");
        });
    }

    public void appendToLastAssistantMessage(String text) {
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

    public void completeLastMessage() {
        currentAssistantMessage = null;
        updateReadyStatus("gemma2:2b");
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

    public void setThinkingIndicator(boolean thinking) {
        thinkingIndicator.setVisible(thinking);
    }

    public void setModeIndicator(String mode) {
        modeLabel.setText(mode);
    }

    // Getters
    public Scene getScene() { return scene; }
    public TextArea getMessageInput() { return messageInput; }
    public Button getSendButton() { return sendButton; }
    public Button getUploadImageButton() { return uploadImageButton; }
    public Button getStopButton() { return stopButton; }
    public Button getTextModeButton() { return textModeButton; }
    public Button getImageModeButton() { return imageModeButton; }
}