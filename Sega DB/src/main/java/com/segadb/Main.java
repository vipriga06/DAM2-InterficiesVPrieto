package com.segadb;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class Main extends Application {

    @Override
    public void start(Stage primaryStage) throws Exception {
        // Carga el archivo FXML principal
        FXMLLoader loader = new FXMLLoader(getClass().getResource("/assets/viewMain.fxml"));
        Parent root = loader.load();

        primaryStage.setTitle("Sega DB");
        primaryStage.setScene(new Scene(root));
        primaryStage.show();
    }

    public static void main(String[] args) {
        launch(args);
    }
}
