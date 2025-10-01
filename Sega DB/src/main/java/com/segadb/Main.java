package com.segadb;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class Main extends Application {

    @Override
    public void start(Stage stage) throws Exception {
        try {
            // Carga la vista principal
            FXMLLoader fxmlLoader = new FXMLLoader(Main.class.getResource("/assets/viewMain.fxml"));
            Scene scene = new Scene(fxmlLoader.load());
            
            // Configura el controlador
            ControllerMain controller = fxmlLoader.getController();
            
            // Establece la escena y muestra la ventana
            stage.setTitle("Sega DB");
            stage.setScene(scene);
            stage.show();
            
            // Configura el stage después de mostrarlo
            controller.setStage(stage);
            
        } catch (Exception e) {
            e.printStackTrace();
            throw e;
        }
    }

    public static void main(String[] args) {
        launch(args);
    }
}
