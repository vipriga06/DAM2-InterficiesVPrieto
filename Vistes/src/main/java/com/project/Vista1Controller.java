package com.project;

import java.net.URL;
import java.util.ResourceBundle;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.TextField;

public class Vista1Controller implements Initializable {
    
    @FXML
    private TextField nomField;
    
    @FXML
    private TextField edatField;
    
    @FXML
    private Button switchButton;
    
    private Main mainApp;
    
    @Override
    public void initialize(URL url, ResourceBundle rb) {
        // Desactiva inicialment el botó
        switchButton.setDisable(true);
        
        // Escolta els canvis als camps de text per activar/desactivar el botó
        nomField.textProperty().addListener((obs, oldVal, newVal) -> validateFields());
        edatField.textProperty().addListener((obs, oldVal, newVal) -> validateFields());
    }
    
    private void validateFields() {
        switchButton.setDisable(nomField.getText().trim().isEmpty() || edatField.getText().trim().isEmpty());
    }
    
    // Cridat quan es clica el botó
    @FXML
    private void handleSwitch() {
        // Actualitza les variables estàtiques
        Main.nom = nomField.getText().trim();
        Main.edat = edatField.getText().trim();
        
        // Canvia a la segona vista
        mainApp.switchToVista2();
    }
    
    // Setter per la referència a Main (injectat via carregador FXML si cal)
    public void setMainApp(Main mainApp) {
        this.mainApp = mainApp;
    }
}
