package com.segadb;

import com.utils.UtilsViews;

import javafx.application.Application;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class Main extends Application {

    private static final double MOBILE_BREAKPOINT = 500;
    private static final String VIEW_MAIN = "ViewMain";
    private static final String VIEW_MAIN_MOBILE = "ViewMainMobile";
    private static final String VIEW_DETAIL_MOBILE = "ViewDetailMobile";

    private boolean isMobileView = false;

    @Override
    public void start(Stage stage) throws Exception {
        try {
            UtilsViews.addView(Main.class, VIEW_MAIN, "/assets/viewMain.fxml");
            UtilsViews.addView(Main.class, VIEW_MAIN_MOBILE, "/assets/viewMainMobile.fxml");
            UtilsViews.addView(Main.class, VIEW_DETAIL_MOBILE, "/assets/viewDetailMobile.fxml");

            Scene scene = new Scene(UtilsViews.parentContainer, 700, 400);
            
            stage.setTitle("Sega DB");
            stage.setScene(scene);
            stage.setMinWidth(300);
            stage.setMinHeight(400);
            stage.show();

            stage.widthProperty().addListener((obs, oldVal, newVal) -> {
                boolean newIsMobile = newVal.doubleValue() < MOBILE_BREAKPOINT;
                if (newIsMobile != isMobileView) {
                    switchMainView(newIsMobile);
                }
            });

            isMobileView = stage.getWidth() < MOBILE_BREAKPOINT;
            if (isMobileView) {
                UtilsViews.setView(VIEW_MAIN_MOBILE);
            } else {
                UtilsViews.setView(VIEW_MAIN);
            }

        } catch (Exception e) {
            System.err.println("Error iniciant Sega DB: " + e.getMessage());
            throw e;
        }
    }

    public static void main(String[] args) {
        launch(args);
    }

    private void switchMainView(boolean newIsMobile) {
        String currentViewId = isMobileView ? VIEW_MAIN_MOBILE : VIEW_MAIN;
        ControllerMain currentController = (ControllerMain) UtilsViews.getController(currentViewId);
        String filterToPreserve = currentController != null ? currentController.getCurrentFilter() : "Tots";
        String typeToPreserve = currentController != null ? currentController.getCurrentType() : "character";

        isMobileView = newIsMobile;
        String targetViewId = newIsMobile ? VIEW_MAIN_MOBILE : VIEW_MAIN;
        UtilsViews.setView(targetViewId);

        ControllerMain targetController = (ControllerMain) UtilsViews.getController(targetViewId);
        if (targetController != null) {
            targetController.setCurrentType(typeToPreserve);
            targetController.setCurrentFilter(filterToPreserve);
        }
    }
}