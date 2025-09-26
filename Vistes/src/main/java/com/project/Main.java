package com.project;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class Main extends Application {

    public static String nom = "";
    public static String edat = "";

    private static Stage primaryStage;

    @Override
    public void start(Stage stage) throws Exception {
        primaryStage = stage;
        FXMLLoader loader = new FXMLLoader(getClass().getResource("/assets/Vista1.fxml"));
        Scene scene = new Scene(loader.load());
        stage.setScene(scene);
        stage.setTitle("Formulari");
        stage.show();
    }

    public static void canviaVista(String fxml) throws Exception {
        FXMLLoader loader = new FXMLLoader(Main.class.getResource("/assets/" + fxml));
        Scene scene = new Scene(loader.load());
        primaryStage.setScene(scene);
    }


    public static void main(String[] args) {
        launch(args);
    }
}
