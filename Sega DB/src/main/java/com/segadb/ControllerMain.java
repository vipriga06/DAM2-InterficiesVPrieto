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
    private String currentType = "characters"; // Tipo por defecto

    @FXML
    public void initialize() {
        loadCharactersFromJson();
        setupTypeChoice();
        setupCategoryChoice();
        refreshList();
    }

    /**
     * Configura el ChoiceBox con los tipos disponibles
     */
    private void setupTypeChoice() {
        if (typeChoice != null) {
            typeChoice.getItems().addAll("characters", "games", "consoles");
            typeChoice.setValue("characters");

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

    /**
     * Actualiza las categorías según el tipo seleccionado
     */
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

    /**
     * Configura el ChoiceBox con las categorías disponibles
     */
    private void setupCategoryChoice() {
        if (categoryChoice != null) {
            updateCategoryChoice();

            // Listener para filtrar cuando cambia la selección
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

    /**
     * Carga los datos desde el JSON
     */
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
                String type = obj.getString("type"); // Nuevo campo

                allCharacters.add(new CharacterData(name, imageFile, color, game, type));
            }

            System.out.println("Datos cargados: " + allCharacters.size());
        } catch (Exception e) {
            System.err.println("Error cargando el archivo JSON:");
            e.printStackTrace();
        }
    }

    /**
     * Refresca la lista según los filtros actuales
     */
    public void refreshList() {
        if (list1 == null) return;

        list1.getChildren().clear();

        // Filtrar por tipo y categoría
        List<CharacterData> filteredCharacters = allCharacters.stream()
            .filter(c -> c.getType().equals(currentType))
            .collect(Collectors.toList());

        if (!"Tots".equals(currentFilter)) {
            filteredCharacters = filteredCharacters.stream()
                .filter(c -> c.getGame().equals(currentFilter))
                .collect(Collectors.toList());
        }

        try {
            for (CharacterData character : filteredCharacters) {
                FXMLLoader loader = new FXMLLoader(
                    getClass().getResource("/assets/subviewCharacters.fxml")
                );
                AnchorPane item = loader.load();

                ControllerItem1 controllerItem = loader.getController();
                controllerItem.setTitle(character.getName());
                controllerItem.setSubtitle(character.getGame());
                controllerItem.setImage("/assets/imagesTot/" + character.getImage());
                controllerItem.setCircleColor(character.getColor());

                // Gestionar el clic sobre el item
                item.setOnMouseClicked(event -> selectCharacter(character));

                list1.getChildren().add(item);
            }
        } catch (Exception e) {
            System.err.println("Error cargando los items:");
            e.printStackTrace();
        }
    }

    /**
     * Selecciona un elemento y actualiza la información
     */
    private void selectCharacter(CharacterData character) {
        System.out.println("Seleccionado: " + character.getName());
        
        if (image != null) {
            try {
                Image img = new Image(
                    getClass().getResourceAsStream("/assets/imagesTot/" + character.getImage())
                );
                image.setImage(img);
            } catch (Exception e) {
                System.err.println("Error cargando la imagen: " + character.getImage());
            }
        }
        
        if (nom != null) {
            nom.setText(character.getName());
        }
        
        if (nom1 != null) {
            nom1.setText(character.getGame());
        }
    }

    // Getters y setters para sincronización
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
}