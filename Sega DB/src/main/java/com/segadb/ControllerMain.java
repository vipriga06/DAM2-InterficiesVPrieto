package com.segadb;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;
import java.util.stream.Collectors;

import org.json.JSONArray;
import org.json.JSONObject;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.control.ChoiceBox;
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

    @FXML
    private ChoiceBox<String> categoryChoice;

    @FXML
    private ChoiceBox<String> typeChoice; // Nuevo ChoiceBox para tipos

    private List<CharacterData> allCharacters = new ArrayList<>();
    private String currentFilter = "Tots";
    private String currentType = "character";

    @FXML
    public void initialize() {
        System.out.println("Inicialitzant controlador...");
        loadCharactersFromJson();
        setupTypeChoice();
        setupCategoryChoice();
        System.out.println("Cridant refreshList...");
        refreshList();
        System.out.println("RefreshList completat");
    }

    private void setupTypeChoice() {
        if (typeChoice != null) {
            typeChoice.getItems().addAll("character", "game", "console");
            typeChoice.setValue("character");

            typeChoice.getSelectionModel().selectedItemProperty().addListener(
                (observable, oldValue, newValue) -> {
                    if (newValue != null) {
                        currentType = newValue;
                        updateCategoryChoice();
                        refreshList();
                    }
                }
            );
        }
    }

    private void updateCategoryChoice() {
        if (categoryChoice != null) {
            categoryChoice.getItems().clear();
            
            List<String> categories = allCharacters.stream()
                .filter(c -> c.getType().equals(currentType))
                .map(CharacterData::getGame)
                .distinct()
                .sorted()
                .collect(Collectors.toList());

            categoryChoice.getItems().add("Tots");
            categoryChoice.getItems().addAll(categories);
            categoryChoice.setValue("Tots");
            currentFilter = "Tots";
        }
    }

    private void setupCategoryChoice() {
        if (categoryChoice != null) {
            updateCategoryChoice();

            categoryChoice.getSelectionModel().selectedItemProperty().addListener(
                (observable, oldValue, newValue) -> {
                    if (newValue != null) {
                        currentFilter = newValue;
                        refreshList();
                    }
                }
            );
        }
    }

    private void loadCharactersFromJson() {
        try (InputStream is = getClass().getResourceAsStream("/assets/data/characters_sega.json")) {
            if (is == null) {
                System.err.println("No s'ha trobat el fitxer JSON");
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
                String imageFile = obj.getString("image");
                String color = obj.getString("color");
                String game = obj.getString("game");
                String type = obj.getString("type");

                allCharacters.add(new CharacterData(name, imageFile, color, game, type));
            }

            System.out.println("Dades carregades: " + allCharacters.size());
        } catch (Exception e) {
            System.err.println("Error carregant l'arxiu JSON:");
            e.printStackTrace();
        }
    }

    public void refreshList() {
        System.out.println("refreshList cridat");
        if (list1 == null) {
            System.err.println("ERROR: list1 és null!");
            return;
        }

        list1.getChildren().clear();
        System.out.println("Total elements: " + allCharacters.size());
        System.out.println("Tipus actual: " + currentType);

        List<CharacterData> filteredCharacters = allCharacters.stream()
            .filter(c -> c.getType().equals(currentType))
            .collect(Collectors.toList());

        System.out.println("Elements filtrats per tipus: " + filteredCharacters.size());

        if (!"Tots".equals(currentFilter)) {
            filteredCharacters = filteredCharacters.stream()
                .filter(c -> c.getGame().equals(currentFilter))
                .collect(Collectors.toList());
            System.out.println("Elements filtrats per categoria: " + filteredCharacters.size());
        }

        System.out.println("Intentant cargar " + filteredCharacters.size() + " elements...");
        
        try {
            for (CharacterData character : filteredCharacters) {
                System.out.println("Cargant: " + character.getName());
                FXMLLoader loader = new FXMLLoader(
                    getClass().getResource("/assets/subviewCharacters.fxml")
                );
                AnchorPane item = loader.load();

                ControllerItem1 controllerItem = loader.getController();
                controllerItem.setTitle(character.getName());
                controllerItem.setSubtitle(character.getGame());
                
                String imagePath = character.getImage();
                String fullImagePath = "/assets/images/" + imagePath;
                System.out.println("Intentant cargar imatge: " + fullImagePath);
                controllerItem.setImage(fullImagePath);
                controllerItem.setCircleColor(character.getColor());
                controllerItem.setCharacterData(character);

                item.setOnMouseClicked(event -> {
                    selectCharacter(character);
                    if (list1.getScene() != null && list1.getScene().getWindow() != null) {
                        double sceneWidth = list1.getScene().getWidth();
                        if (sceneWidth < 500) {
                            ControllerDetailMobile detailCtrl = (ControllerDetailMobile) com.utils.UtilsViews.getController("ViewDetailMobile");
                            if (detailCtrl != null) {
                                detailCtrl.setCharacterData(character);
                            }
                            com.utils.UtilsViews.setViewAnimating("ViewDetailMobile");
                        }
                    }
                });

                list1.getChildren().add(item);
                System.out.println("Element agregat a list1");
            }
            System.out.println("Total elements a list1: " + list1.getChildren().size());
        } catch (Exception e) {
            System.err.println("Error cargant els elements:");
            e.printStackTrace();
        }
    }

    private void selectCharacter(CharacterData character) {
        System.out.println("Seleccionat: " + character.getName());
        
        if (image != null) {
            try {
                String imagePath = character.getImage();
                String fullImagePath = "/assets/images/" + imagePath;
                java.io.InputStream is = getClass().getResourceAsStream(fullImagePath);
                if (is == null) {
                    System.err.println("No s'ha trobat la imatge: " + fullImagePath);
                    return;
                }
                Image img = new Image(is);
                image.setImage(img);
                System.out.println("Imatge seleccionada carregada: " + fullImagePath);
            } catch (Exception e) {
                System.err.println("Error cargant la imatge: " + character.getImage());
                e.printStackTrace();
            }
        }
        
        if (nom != null) {
            nom.setText(character.getName());
        }
        
        if (nom1 != null) {
            nom1.setText(character.getGame());
        }
    }

    public String getCurrentFilter() { return currentFilter; }
    public String getCurrentType() { return currentType; }

    public void setCurrentFilter(String filter) {
        this.currentFilter = filter;
        if (categoryChoice != null) {
            categoryChoice.setValue(filter);
        }
        refreshList();
    }

    public void setCurrentType(String type) {
        this.currentType = type;
        if (typeChoice != null) {
            typeChoice.setValue(type);
        }
        updateCategoryChoice();
    }

    public void selectCharacterFromDetail(CharacterData character) {
        System.out.println("Seleccionant des de detall: " + character.getName());
        selectCharacter(character);
    }
}