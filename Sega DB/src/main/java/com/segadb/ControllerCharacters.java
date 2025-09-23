package com.segadb;

import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ResourceBundle;

import org.json.JSONArray;
import org.json.JSONObject;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Parent;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.VBox;

public class ControllerCharacters implements Initializable {

    @FXML
    private ImageView imgArrowBack;

    @FXML
    private VBox list;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        Path imagePath = null;
        try {
            URL imageURL = getClass().getResource("/assets/imagesTot/arrow-back.png");
            Image image = new Image(imageURL.toExternalForm());
            imgArrowBack.setImage(image);
        } catch (Exception e) {
            System.err.println("Error loading image asset: " + imagePath);
            e.printStackTrace();
        }
    }

    public void loadList() {
        try {
            URL jsonFileURL = getClass().getResource("/assets/data/characters.json");
            Path path = Paths.get(jsonFileURL.toURI());
            String content = new String(Files.readAllBytes(path), StandardCharsets.UTF_8);
            JSONArray jsonInfo = new JSONArray(content);
            String pathImages = "/assets/imagesTot/";
            
            list.getChildren().clear();
            for (int i = 0; i < jsonInfo.length(); i++) {
                JSONObject character = jsonInfo.getJSONObject(i);
                String name = character.getString("name");
                String image = character.getString("image");
                String color = character.getString("color");
                String game = character.getString("game");
                
                // TODO: Aquí carregar subvista  
                // amb les dades de cada objecte enlloc d'un Label
                URL resource = this.getClass().getResource("/assets/subviewCharacters.fxml");
                FXMLLoader loader = new FXMLLoader(resource);
                Parent itemPane = loader.load();
                ControllerItem1 itemController = loader.getController();

                itemController.setCircleColor(color);
                itemController.setImage(pathImages + image);
                itemController.setTitle(name);
                itemController.setSubtitle(game);
                

                // Afegir el nou element a l'espai que l'hi hem reservat (itemBox)
                list.getChildren().add(itemPane);

                // Label label = new Label(name);
                // label.setStyle("-fx-border-color: green;");
                // list.getChildren().add(label);
            }
        } catch (Exception e) {
            System.err.println("Error al cargar la lista de personajes");
            e.printStackTrace();
        }
    }

    @FXML
    private void toViewMain(MouseEvent event) {
        UtilsViews.setViewAnimating("ViewMain");
    }
}
