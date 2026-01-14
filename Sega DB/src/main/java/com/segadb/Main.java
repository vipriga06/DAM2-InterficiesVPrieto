package com.segadb;

import com.utils.UtilsViews;

import javafx.application.Application;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class Main extends Application {

    private boolean isMobileView = false;

    @Override
    public void start(Stage stage) throws Exception {
        try {
            UtilsViews.addView(Main.class, "ViewMain", "/assets/viewMain.fxml");
            UtilsViews.addView(Main.class, "ViewMainMobile", "/assets/viewMainMobile.fxml");
            UtilsViews.addView(Main.class, "ViewDetailMobile", "/assets/viewDetailMobile.fxml");

            Scene scene = new Scene(UtilsViews.parentContainer, 700, 400);
            
            stage.setTitle("Sega DB");
            stage.setScene(scene);
            stage.setMinWidth(300);
            stage.setMinHeight(400);
            stage.show();

            stage.widthProperty().addListener((obs, oldVal, newVal) -> {
                boolean newIsMobile = newVal.doubleValue() < 500;
                
                if (newIsMobile != isMobileView) {
                    isMobileView = newIsMobile;
                    
                    if (newIsMobile) {
                        UtilsViews.setView("ViewMainMobile");
                        ControllerMain controller = (ControllerMain) UtilsViews.getController("ViewMainMobile");
                        if (controller != null) {
                            controller.refreshList();
                        }
                    } else {
                        UtilsViews.setView("ViewMain");
                        ControllerMain controller = (ControllerMain) UtilsViews.getController("ViewMain");
                        if (controller != null) {
                            controller.refreshList();
                        }
                    }
                }
            });

            isMobileView = stage.getWidth() < 500;
            if (isMobileView) {
                UtilsViews.setView("ViewMainMobile");
            } else {
                UtilsViews.setView("ViewMain");
            }

        } catch (Exception e) {
            e.printStackTrace();
            throw e;
        }
    }

    public static void main(String[] args) {
        launch(args);
    }
}