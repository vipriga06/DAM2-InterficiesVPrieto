package com.project;

import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.TextField;

public class Controller {
    @FXML
    private TextField resultField;

    private double previous = 0;
    private String operator = null;
    private boolean newInput = true;

    @FXML
    private void handleNumber(ActionEvent event) {
        String buttonText = ((Button) event.getSource()).getText();
        if (newInput) {
            resultField.setText(buttonText);
            newInput = false;
        } else {
            resultField.setText(resultField.getText() + buttonText);
        }
    }

    @FXML
    private void handleOperator(ActionEvent event) {
        String buttonText = ((Button) event.getSource()).getText();

        if (operator != null && !newInput) {
            // Si ya hay un operador y un número, calcula antes de asignar el nuevo
            handleEquals(null);
        }

        previous = Double.parseDouble(resultField.getText());
        operator = buttonText;
        newInput = true;
    }

    @FXML
    private void handleEquals(ActionEvent event) {
        if (operator == null || newInput) return;

        double current = Double.parseDouble(resultField.getText());
        double result = 0;

        switch (operator) {
            case "+" -> result = previous + current;
            case "-" -> result = previous - current;
            case "*" -> result = previous * current;
            case "/" -> result = current != 0 ? previous / current : 0;
        }

        resultField.setText(String.valueOf(result));
        previous = result;
        operator = null;
        newInput = true;
    }

    @FXML
    private void handleClear(ActionEvent event) {
        resultField.setText("");
        previous = 0;
        operator = null;
        newInput = true;
    }
}
