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
                    
                    ControllerMain currentController = (ControllerMain) UtilsViews.getController(isMobileView ? "ViewMain" : "ViewMainMobile");
                    String filterToPreserve = currentController != null ? currentController.getCurrentFilter() : "Tots";
                    String typeToPreserve = currentController != null ? currentController.getCurrentType() : "character";
                    
                    if (newIsMobile) {
                        UtilsViews.setView("ViewMainMobile");
                        ControllerMain mobileController = (ControllerMain) UtilsViews.getController("ViewMainMobile");
                        if (mobileController != null) {
                            mobileController.setCurrentType(typeToPreserve);
                            mobileController.setCurrentFilter(filterToPreserve);
                        }
                    } else {
                        UtilsViews.setView("ViewMain");
                        ControllerMain desktopController = (ControllerMain) UtilsViews.getController("ViewMain");
                        if (desktopController != null) {
                            desktopController.setCurrentType(typeToPreserve);
                            desktopController.setCurrentFilter(filterToPreserve);
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