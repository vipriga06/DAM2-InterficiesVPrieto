package com.segadb;

import com.segadb.service.ImageCache;
import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.image.ImageView;
import javafx.scene.layout.VBox;

public class ControllerDetailMobile {

    private static final String MAIN_VIEW_ID = "ViewMain";
    private static final String MAIN_MOBILE_VIEW_ID = "ViewMainMobile";
    private static final String IMAGE_BASE_PATH = "/assets/images/";

    private final ImageCache imageCache = new ImageCache();

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

    private SegaItemData currentItem;

    @FXML
    public void initialize() {
        if (rootVBox == null) {
            return;
        }

        rootVBox.sceneProperty().addListener((obs, oldScene, newScene) -> registerSceneListeners(newScene));
        registerSceneListeners(rootVBox.getScene());
    }

    private void registerSceneListeners(Scene scene) {
        if (scene == null) {
            return;
        }

        scene.widthProperty().addListener((obs, oldVal, newVal) -> {
            if (newVal.doubleValue() >= 500 && currentItem != null) {
                ControllerMain mainCtrl = (ControllerMain) UtilsViews.getController(MAIN_VIEW_ID);
                if (mainCtrl != null) {
                    mainCtrl.selectItemFromDetail(currentItem);
                }
                UtilsViews.setView(MAIN_VIEW_ID);
            }
        });
    }

    public void setItemData(SegaItemData item) {
        this.currentItem = item;
        updateView();
    }

    private void updateView() {
        if (currentItem == null) {
            return;
        }

        titleLabel.setText(currentItem.getName());
        detailName.setText(currentItem.getName());
        detailGame.setText(currentItem.getGame());
        detailType.setText(currentItem.getType().toUpperCase());

        String fullImagePath = IMAGE_BASE_PATH + currentItem.getImage();
        imageCache.getImage(getClass(), fullImagePath).ifPresent(detailImage::setImage);
    }

    @FXML
    private void onBackClicked() {
        UtilsViews.setViewAnimating(MAIN_MOBILE_VIEW_ID);
    }
}