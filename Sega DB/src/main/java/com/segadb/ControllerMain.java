package com.segadb;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;

public class ControllerMain {

    @FXML
    private ImageView image;

    @FXML
    private ImageView characterImage;




    @FXML
    public void initialize() {
        Image img = new Image(getClass().getResourceAsStream("/icons/sega_icon.gif"));
        image.setImage(img);
        Image img_character = new Image(getClass().getResourceAsStream("/icons/characters-sega.gif"));
        characterImage.setImage(img_character);
        
    }

    @FXML
    private void toViewCharacters(MouseEvent event) {
        System.out.println("To View Characters");
        ControllerCharacters ctrlCharacters = (ControllerCharacters) UtilsViews.getController("ViewCharacters");
        ctrlCharacters.loadList();
        UtilsViews.setViewAnimating("ViewCharacters");
    }



}
