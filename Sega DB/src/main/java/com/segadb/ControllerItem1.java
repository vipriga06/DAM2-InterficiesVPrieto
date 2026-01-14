package com.segadb;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
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

    private CharacterData characterData;

    public void setCharacterData(CharacterData data) {
        this.characterData = data;
    }

    public void setTitle(String title) {
        this.title.setText(title);
    }

    public void setSubtitle(String subtitle) {
        this.subtitle.setText(subtitle);
    }

    public void setImage(String imagePath) {
        try {
            if (imagePath == null || imagePath.isEmpty()) {
                System.err.println("Error: imagePath és nul o buit");
                return;
            }
            
            java.io.InputStream is = getClass().getResourceAsStream(imagePath);
            if (is == null) {
                System.err.println("No s'ha trobat la imatge: " + imagePath);
                return;
            }
            
            Image img = new Image(is);
            this.image.setImage(img);
            System.out.println("Imatge carregada correctament: " + imagePath);
        } catch (Exception e) {
            System.err.println("Error carregant la imatge: " + imagePath);
            e.printStackTrace();
        }
    }

    public void setCircleColor(String color) {
        circle.setStyle("-fx-fill: " + color);
    }

    @FXML
    private void onItemClicked(MouseEvent event) {
        if (UtilsViews.parentContainer.getScene().getWidth() < 500 && characterData != null) {
            try {
                ControllerDetailMobile detailCtrl = (ControllerDetailMobile) UtilsViews.getController("ViewDetailMobile");
                if (detailCtrl != null) {
                    detailCtrl.setCharacterData(characterData);
                }
                UtilsViews.setViewAnimating("ViewDetailMobile");
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
