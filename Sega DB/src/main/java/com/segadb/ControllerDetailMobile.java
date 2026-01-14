package com.segadb;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.VBox;

public class ControllerDetailMobile {

    @FXML
    private VBox rootVBox;
    
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

    @FXML
    public void initialize() {
        if (rootVBox != null && rootVBox.getScene() != null) {
            rootVBox.getScene().getWindow().widthProperty().addListener((obs, oldVal, newVal) -> {
                if (newVal.doubleValue() >= 500 && currentCharacter != null) {
                    ControllerMain mainCtrl = (ControllerMain) UtilsViews.getController("ViewMain");
                    if (mainCtrl != null) {
                        mainCtrl.selectCharacterFromDetail(currentCharacter);
                    }
                    UtilsViews.setView("ViewMain");
                }
            });
        }
    }

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
                String fullImagePath = "/assets/images/" + imagePath;
                java.io.InputStream is = getClass().getResourceAsStream(fullImagePath);
                if (is == null) {
                    System.err.println("No s'ha trobat la imatge: " + fullImagePath);
                    return;
                }
                Image img = new Image(is);
                detailImage.setImage(img);
                System.out.println("Imatge de detall carregada: " + fullImagePath);
            } catch (Exception e) {
                System.err.println("Error cargant la imatge: " + currentCharacter.getImage());
                e.printStackTrace();
            }
        }
    }

    @FXML
    private void onBackClicked() {
        UtilsViews.setViewAnimating("ViewMainMobile");
    }
}