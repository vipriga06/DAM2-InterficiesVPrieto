package com.segadb;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.segadb.data.JsonSegaItemRepository;
import com.segadb.data.SegaItemRepository;
import com.segadb.service.ImageCache;
import com.segadb.service.SegaItemFilterService;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.control.ChoiceBox;
import javafx.scene.image.ImageView;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.VBox;
import javafx.scene.text.Text;

public class ControllerMain {

    private static final String ALL_CATEGORIES = "Tots";
    private static final String DEFAULT_TYPE = "character";
    private static final String SUBVIEW_ITEM_PATH = "/assets/subviewCharacters.fxml";
    private static final String IMAGE_BASE_PATH = "/assets/images/";
    private static final String DETAIL_MOBILE_VIEW_ID = "ViewDetailMobile";

    private final SegaItemRepository itemRepository =
        new JsonSegaItemRepository("/assets/data/characters_sega.json");
    private final SegaItemFilterService filterService = new SegaItemFilterService();
    private final ImageCache imageCache = new ImageCache();
    private final Map<SegaItemData, AnchorPane> itemNodeCache = new HashMap<>();

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
    private ChoiceBox<String> typeChoice;

    private List<SegaItemData> allItems = new ArrayList<>();
    private SegaItemData selectedItem;
    private String currentFilter = ALL_CATEGORIES;
    private String currentType = DEFAULT_TYPE;

    @FXML
    public void initialize() {
        loadItems();
        setupTypeChoice();
        setupCategoryChoice();
        refreshList();
    }

    private void loadItems() {
        allItems = itemRepository.loadItems();
        filterService.index(allItems);
    }

    private void setupTypeChoice() {
        if (typeChoice == null) {
            return;
        }

        List<String> availableTypes = filterService.getAvailableTypes();
        if (availableTypes.isEmpty()) {
            availableTypes = List.of("character", "game", "console");
        }

        typeChoice.getItems().setAll(availableTypes);
        if (!availableTypes.contains(currentType)) {
            currentType = availableTypes.get(0);
        }
        typeChoice.setValue(currentType);

        typeChoice.getSelectionModel().selectedItemProperty().addListener(
            (observable, oldValue, newValue) -> {
                if (newValue != null && !newValue.equals(oldValue)) {
                    currentType = newValue;
                    updateCategoryChoice(true);
                    refreshList();
                }
            }
        );
    }

    private void updateCategoryChoice(boolean resetFilter) {
        if (categoryChoice == null) {
            return;
        }

        List<String> categories = filterService.getCategoriesForType(currentType);
        categoryChoice.getItems().setAll(ALL_CATEGORIES);
        categoryChoice.getItems().addAll(categories);

        if (resetFilter || !categoryChoice.getItems().contains(currentFilter)) {
            currentFilter = ALL_CATEGORIES;
        }
        categoryChoice.setValue(currentFilter);
    }

    private void setupCategoryChoice() {
        if (categoryChoice == null) {
            return;
        }

        updateCategoryChoice(true);
        categoryChoice.getSelectionModel().selectedItemProperty().addListener(
            (observable, oldValue, newValue) -> {
                if (newValue != null && !newValue.equals(oldValue)) {
                    currentFilter = newValue;
                    refreshList();
                }
            }
        );
    }

    public void refreshList() {
        if (list1 == null) {
            return;
        }

        List<SegaItemData> filteredItems = filterService.filter(currentType, currentFilter);
        List<AnchorPane> cachedNodes = new ArrayList<>(filteredItems.size());
        for (SegaItemData item : filteredItems) {
            cachedNodes.add(getOrCreateItemNode(item));
        }
        list1.getChildren().setAll(cachedNodes);

        if (!filteredItems.isEmpty() && selectedItem == null) {
            handleItemSelected(filteredItems.get(0));
        }
    }

    private AnchorPane getOrCreateItemNode(SegaItemData item) {
        AnchorPane existingNode = itemNodeCache.get(item);
        if (existingNode != null) {
            return existingNode;
        }

        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource(SUBVIEW_ITEM_PATH));
            AnchorPane node = loader.load();
            ControllerItem1 itemController = loader.getController();

            String fullImagePath = IMAGE_BASE_PATH + item.getImage();
            itemController.bindData(item, imageCache.getImage(getClass(), fullImagePath).orElse(null));
            itemController.setOnItemSelected(this::handleItemSelected);
            node.setOnMouseClicked(event -> itemController.notifySelection());

            itemNodeCache.put(item, node);
            return node;
        } catch (IOException e) {
            throw new IllegalStateException("No s'ha pogut carregar la vista d'un item", e);
        }
    }

    private void handleItemSelected(SegaItemData item) {
        selectedItem = item;
        selectItem(item);

        if (isMobileLayout()) {
            ControllerDetailMobile detailCtrl =
                (ControllerDetailMobile) com.utils.UtilsViews.getController(DETAIL_MOBILE_VIEW_ID);
            if (detailCtrl != null) {
                detailCtrl.setItemData(item);
            }
            com.utils.UtilsViews.setViewAnimating(DETAIL_MOBILE_VIEW_ID);
        }
    }

    private boolean isMobileLayout() {
        return list1 != null && list1.getScene() != null && list1.getScene().getWidth() < 500;
    }

    private void selectItem(SegaItemData item) {
        if (image != null) {
            String fullImagePath = IMAGE_BASE_PATH + item.getImage();
            imageCache.getImage(getClass(), fullImagePath).ifPresent(image::setImage);
        }

        if (nom != null) {
            nom.setText(item.getName());
        }

        if (nom1 != null) {
            nom1.setText(item.getGame());
        }
    }

    public String getCurrentFilter() { return currentFilter; }
    public String getCurrentType() { return currentType; }

    public void setCurrentFilter(String filter) {
        this.currentFilter = (filter == null || filter.isBlank()) ? ALL_CATEGORIES : filter;
        if (categoryChoice != null) {
            if (!categoryChoice.getItems().contains(this.currentFilter)) {
                this.currentFilter = ALL_CATEGORIES;
            }
            categoryChoice.setValue(this.currentFilter);
        }
        refreshList();
    }

    public void setCurrentType(String type) {
        this.currentType = (type == null || type.isBlank()) ? DEFAULT_TYPE : type;
        if (typeChoice != null) {
            if (!typeChoice.getItems().contains(this.currentType) && !typeChoice.getItems().isEmpty()) {
                this.currentType = typeChoice.getItems().get(0);
            }
            typeChoice.setValue(this.currentType);
        }
        updateCategoryChoice(true);
        refreshList();
    }

    public void selectItemFromDetail(SegaItemData item) {
        selectedItem = item;
        selectItem(item);
    }
}