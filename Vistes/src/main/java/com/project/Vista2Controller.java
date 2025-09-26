package com.project;

import java.net.URL;
import java.util.ResourceBundle;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.Label;

public class Vista2Controller implements Initializable {
    
    @FXML
    private Label greetingLabel;
    
    @FXML
    private Button backButton;
    
    private Main mainApp;
    
    @Override
    public void initialize(URL url, ResourceBundle rb) {
        // Mostra la salutació utilitzant les variables estàtiques
        greetingLabel.setText("Hola " + Main.nom + ", tens " + Main.edat + " anys!");
    }
    
    // Cridat quan es clica el botó de tornada
    @FXML
    private void handleBack() {
        mainApp.switchToVista1();
    }
    
    // Setter per la referència a Main
    public void setMainApp(Main mainApp) {
        this.mainApp = mainApp;
    }
}
