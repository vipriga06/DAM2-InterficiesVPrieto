package com.xat_ieti;

import javafx.application.Platform;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.*;
import javafx.scene.text.Font;
import java.util.ArrayList;
import java.util.List;

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

        // Área de chat
        chatContainer = createChatContainer();
        scrollPane = new ScrollPane(chatContainer);
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

        scene = new Scene(root);
        applyStyles();
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

    public void addUserMessage(String message) {
        Platform.runLater(() -> {
            HBox bubble = createMessageBubble(message, "user");
            chatContainer.getChildren().add(bubble);
            scrollToBottom();
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
                // Acceso corregido: El HBox contiene un VBox, y el VBox contiene el Label de contenido en la posición 1
                VBox bubbleVBox = (VBox) lastBubble.getChildren().get(0);
                Label content = (Label) bubbleVBox.getChildren().get(1);
                content.setText(currentAssistantMessage);
            }
            scrollToBottom();
        });
    }

    public void completeLastMessage() {
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
        // Actúa sobre el ScrollPane, no sobre el VBox.
        // Platform.runLater asegura que el scroll ocurra después de que se añada el nuevo contenido.
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