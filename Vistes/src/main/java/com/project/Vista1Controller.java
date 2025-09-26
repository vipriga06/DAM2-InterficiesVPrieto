package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Alert;
import javafx.scene.control.Alert.AlertType;
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

        if (nom.isEmpty() || edat.isEmpty()) {
            mostraError("Has d'omplir tots els camps.");
            return;
        }

        if (!nom.matches("[a-zA-ZÀ-ÿ\\s]+")) {
            mostraError("El nom només pot contenir lletres.");
            return;
        }

        if (!edat.matches("\\d+")) {
            mostraError("L'edat ha de ser un número enter.");
            return;
        }

        Main.nom = nom;
        Main.edat = edat;
        Main.canviaVista("Vista2.fxml");
    }

    private void mostraError(String missatge) {
        Alert alert = new Alert(AlertType.ERROR);
        alert.setTitle("Error de validació");
        alert.setHeaderText(null);
        alert.setContentText(missatge);
        alert.showAndWait();
    }
}
