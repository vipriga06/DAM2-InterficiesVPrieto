package com.segadb;

import java.util.Objects;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.shape.Circle;

public class ControllerItem1 {

    @FXML
    private Label title;      // Per al nom del personatge

    @FXML
    private Label subtitle;   // Per al nom del joc

    @FXML
    private ImageView image;  // Imatge del personatge

    @FXML
    private Circle circle;    // Cercle per mostrar el color

    // Estableix el títol (nom)
    public void setTitle(String title) {
        this.title.setText(title);
    }

    // Estableix el subtítol (nom del joc)
    public void setSubtitle(String subtitle) {
        this.subtitle.setText(subtitle);
    }

    // Carrega la imatge des de ruta relativa (ha de ser ruta completa en classpath)
    public void setImage(String imagePath) {
        try {
            Image img = new Image(Objects.requireNonNull(getClass().getResourceAsStream(imagePath)));
            this.image.setImage(img);
        } catch (NullPointerException e) {
            System.err.println("Error carregant la imatge: " + imagePath);
            e.printStackTrace();
        }
    }

    // Canvia el color de fons del cercle
    public void setCircleColor(String color) {
        circle.setStyle("-fx-fill: " + color);
    }

    @FXML
    private void onItemClicked(MouseEvent event) {
        // Para vista móvil, ir a vista detalle
        if (UtilsViews.parentContainer.getScene().getWidth() < 500) {
            try {
                ControllerDetailMobile detailCtrl = (ControllerDetailMobile) UtilsViews.getController("ViewDetailMobile");
                if (detailCtrl != null) {
                    // Necesitaríamos pasar los datos del personaje aquí
                    // Esto requeriría modificar la estructura para almacenar los datos
                }
                UtilsViews.setViewAnimating("ViewDetailMobile");
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
