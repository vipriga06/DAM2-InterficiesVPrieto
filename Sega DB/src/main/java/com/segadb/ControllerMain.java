package com.segadb;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

import org.json.JSONArray;
import org.json.JSONObject;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.VBox;
import javafx.scene.text.Text;

public class ControllerMain {

    @FXML
    private VBox list1;

    @FXML
    private ImageView image;

    @FXML
    private Text nom;

    @FXML
    private Text nom1;

    private List<CharacterData> characters = new ArrayList<>();

    @FXML
    public void initialize() {
        loadCharactersFromJson();
        System.out.println("Personajes cargados: " + characters.size());

        try {
            for (CharacterData character : characters) {
                System.out.println("Cargando personaje: " + character.getName());
                FXMLLoader loader = new FXMLLoader(getClass().getResource("/assets/subviewCharacters.fxml"));
                AnchorPane item = loader.load(); // Cambiar VBox por AnchorPane aquí

                ControllerItem1 controllerItem = loader.getController();
                controllerItem.setTitle(character.getName());
                controllerItem.setSubtitle(character.getGame());
                controllerItem.setImage("/assets/imagesTot/" + character.getImage());
                controllerItem.setCircleColor(character.getColor());

                item.setOnMouseClicked(event -> {
                    System.out.println("Seleccionado: " + character.getName());
                    image.setImage(new Image(getClass().getResourceAsStream("/assets/imagesTot/" + character.getImage())));
                    nom.setText(character.getName());
                    nom1.setText(character.getGame());
                });

                list1.getChildren().add(item);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void loadCharactersFromJson() {
        try (InputStream is = getClass().getResourceAsStream("/assets/data/characters_sega.json")) {
            if (is == null) {
                System.err.println("No se encontró el archivo JSON");
                return;
            }

            String jsonText;
            try (Scanner scanner = new Scanner(is, StandardCharsets.UTF_8.name())) {
                jsonText = scanner.useDelimiter("\\A").next();
            }

            JSONArray array = new JSONArray(jsonText);

            for (int i = 0; i < array.length(); i++) {
                JSONObject obj = array.getJSONObject(i);
                String name = obj.getString("name");
                String image = obj.getString("image");
                String color = obj.getString("color");
                String game = obj.getString("game");

                characters.add(new CharacterData(name, image, color, game));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}