package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.TextField;

public class Vista1Controller {

    @FXML
    private TextField nomField;

    @FXML
    private TextField edatField;

    @FXML
    public void canviaVista2() throws Exception {
        String nom = nomField.getText();
        String edat = edatField.getText();

        if (!nom.isEmpty() && !edat.isEmpty()) {
            Main.nom = nom;
            Main.edat = edat;
            Main.canviaVista("Vista2.fxml");
        }
    }
}
