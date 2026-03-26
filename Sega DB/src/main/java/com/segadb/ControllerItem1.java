package com.segadb;

import java.io.InputStream;
import java.util.function.Consumer;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.shape.Circle;

public class ControllerItem1 {

    @FXML
    private Label title;

    @FXML
    private Label subtitle;

    @FXML
    private ImageView image;

    @FXML
    private Circle circle;

    private SegaItemData itemData;
    private Consumer<SegaItemData> onItemSelected = item -> { };

    public void setItemData(SegaItemData data) {
        this.itemData = data;
    }

    public void setOnItemSelected(Consumer<SegaItemData> onItemSelected) {
        this.onItemSelected = onItemSelected != null ? onItemSelected : item -> { };
    }

    public void bindData(SegaItemData data, Image imageResource) {
        setItemData(data);
        setTitle(data.getName());
        setSubtitle(data.getGame());
        setCircleColor(data.getColor());
        if (imageResource != null) {
            image.setImage(imageResource);
        }
    }

    public void notifySelection() {
        if (itemData != null) {
            onItemSelected.accept(itemData);
        }
    }

    public void setTitle(String title) {
        this.title.setText(title);
    }

    public void setSubtitle(String subtitle) {
        this.subtitle.setText(subtitle);
    }

    public void setImage(String imagePath) {
        if (imagePath == null || imagePath.isEmpty()) {
            System.err.println("Error: imagePath és nul o buit");
            return;
        }

        InputStream is = getClass().getResourceAsStream(imagePath);
        if (is == null) {
            System.err.println("No s'ha trobat la imatge: " + imagePath);
            return;
        }

        Image img = new Image(is);
        this.image.setImage(img);
    }

    public void setCircleColor(String color) {
        circle.setStyle("-fx-fill: " + color);
    }

}
