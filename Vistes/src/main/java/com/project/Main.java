package com.project;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class Main extends Application {
    
    // Variables estàtiques per al pas de dades entre vistes
    static String nom = "";
    static String edat = "";
    
    private Stage stage;
    private Scene vista1Scene;
    private Scene vista2Scene;
    
    @Override
    public void start(Stage primaryStage) throws Exception {
        this.stage = primaryStage;

        // Carrega la primera vista i obté el seu controlador
        FXMLLoader loader1 = new FXMLLoader(getClass().getResource("/assets/vista1.fxml"));
        Parent root1 = loader1.load();
        vista1Scene = new Scene(root1);
        Vista1Controller controller1 = loader1.getController();
        controller1.setMainApp(this);

        // Carrega la segona vista i obté el seu controlador
        FXMLLoader loader2 = new FXMLLoader(getClass().getResource("/assets/vista2.fxml"));
        Parent root2 = loader2.load();
        vista2Scene = new Scene(root2);
        Vista2Controller controller2 = loader2.getController();
        controller2.setMainApp(this);

        // Estableix l'escena inicial
        stage.setScene(vista1Scene);
        stage.setTitle("Exercici 01 - JavaFX");
        stage.show();
    }
    // Mètode per canviar a la segona vista (cridat des del primer controlador)
    public void switchToVista2() {
        stage.setScene(vista2Scene);
    }
    
    // Mètode per tornar a la primera vista (cridat des del segon controlador)
    public void switchToVista1() {
        stage.setScene(vista1Scene);
    }
    
    public static void main(String[] args) {
        launch(args);
    }
}
