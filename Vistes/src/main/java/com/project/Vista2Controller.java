package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Label;

public class Vista2Controller {

    @FXML
    private Label missatgeLabel;

    @FXML
    public void initialize() {
        missatgeLabel.setText("Hola " + Main.nom + ", tens " + Main.edat + " anys!");
    }

    @FXML
    public void tornaVista1() throws Exception {
        Main.canviaVista("Vista1.fxml");
    }
}
