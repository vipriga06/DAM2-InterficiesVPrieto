// ControllerDetailMobile.java
package com.segadb;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;

public class ControllerDetailMobile {

    @FXML
    private Label titleLabel;
    @FXML
    private ImageView detailImage;
    @FXML
    private Label detailName;
    @FXML
    private Label detailGame;
    @FXML
    private Label detailType;

    private CharacterData currentCharacter;

    public void setCharacterData(CharacterData character) {
        this.currentCharacter = character;
        updateView();
    }

    private void updateView() {
        if (currentCharacter != null) {
            titleLabel.setText(currentCharacter.getName());
            detailName.setText(currentCharacter.getName());
            detailGame.setText(currentCharacter.getGame());
            detailType.setText(currentCharacter.getType().toUpperCase());

            try {
                String imagePath = currentCharacter.getImage();
                if (imagePath.contains("/")) {
                    imagePath = imagePath.substring(imagePath.lastIndexOf("/") + 1);
                }
                Image img = new Image(
                    getClass().getResourceAsStream("/assets/images/" + imagePath)
                );
                detailImage.setImage(img);
            } catch (Exception e) {
                System.err.println("Error cargando imagen: " + currentCharacter.getImage());
            }
        }
    }

    @FXML
    private void onBackClicked() {
        UtilsViews.setViewAnimating("ViewMainMobile");
    }
}