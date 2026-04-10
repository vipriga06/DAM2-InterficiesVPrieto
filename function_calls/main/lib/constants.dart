// Defineix les eines/funcions que hi ha disponibles a flutter
const tools = [
  {
    "type": "function",
    "function": {
      "name": "draw_circle",
      "description": "Dibuixa un cercle amb estil de contorn i emplenat.",
      "parameters": {
        "type": "object",
        "properties": {
          "x": {
            "type": ["number", "string"]
          },
          "y": {
            "type": ["number", "string"]
          },
          "radius": {
            "type": ["number", "string"]
          },
          "strokeColor": {"type": "string"},
          "strokeWidth": {
            "type": ["number", "string"]
          },
          "fillMode": {
            "type": "string",
            "enum": ["none", "solid", "linear", "radial"]
          },
          "fillColorA": {"type": "string"},
          "fillColorB": {"type": "string"},
          "gradientAngle": {
            "type": ["number", "string"]
          }
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_line",
      "description": "Dibuixa una línia entre dos punts amb color i gruix.",
      "parameters": {
        "type": "object",
        "properties": {
          "startX": {
            "type": ["number", "string"]
          },
          "startY": {
            "type": ["number", "string"]
          },
          "endX": {
            "type": ["number", "string"]
          },
          "endY": {
            "type": ["number", "string"]
          },
          "strokeColor": {"type": "string"},
          "strokeWidth": {
            "type": ["number", "string"]
          }
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_rectangle",
      "description": "Dibuixa un rectangle amb contorn i emplenat.",
      "parameters": {
        "type": "object",
        "properties": {
          "topLeftX": {
            "type": ["number", "string"]
          },
          "topLeftY": {
            "type": ["number", "string"]
          },
          "bottomRightX": {
            "type": ["number", "string"]
          },
          "bottomRightY": {
            "type": ["number", "string"]
          },
          "strokeColor": {"type": "string"},
          "strokeWidth": {
            "type": ["number", "string"]
          },
          "fillMode": {
            "type": "string",
            "enum": ["none", "solid", "linear", "radial"]
          },
          "fillColorA": {"type": "string"},
          "fillColorB": {"type": "string"},
          "gradientAngle": {
            "type": ["number", "string"]
          }
        },
        "required": ["topLeftX", "topLeftY", "bottomRightX", "bottomRightY"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_text",
      "description": "Dibuixa un text amb tipografia, mida i estil.",
      "parameters": {
        "type": "object",
        "properties": {
          "text": {"type": "string"},
          "x": {
            "type": ["number", "string"]
          },
          "y": {
            "type": ["number", "string"]
          },
          "color": {"type": "string"},
          "fontFamily": {"type": "string"},
          "fontSize": {
            "type": ["number", "string"]
          },
          "fontWeight": {
            "type": "string",
            "enum": ["normal", "bold"]
          },
          "fontStyle": {
            "type": "string",
            "enum": ["normal", "italic"]
          }
        },
        "required": ["text"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "select_shape",
      "description": "Selecciona una figura existent per id.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "string"}
        },
        "required": ["id"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "delete_shape",
      "description":
          "Esborra una figura existent per id o la seleccionada si selected=true.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "selected": {"type": "boolean"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "update_shape",
      "description":
          "Actualitza propietats d'una figura per id o de la seleccionada.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "selected": {"type": "boolean"},
          "x": {
            "type": ["number", "string"]
          },
          "y": {
            "type": ["number", "string"]
          },
          "startX": {
            "type": ["number", "string"]
          },
          "startY": {
            "type": ["number", "string"]
          },
          "endX": {
            "type": ["number", "string"]
          },
          "endY": {
            "type": ["number", "string"]
          },
          "topLeftX": {
            "type": ["number", "string"]
          },
          "topLeftY": {
            "type": ["number", "string"]
          },
          "bottomRightX": {
            "type": ["number", "string"]
          },
          "bottomRightY": {
            "type": ["number", "string"]
          },
          "radius": {
            "type": ["number", "string"]
          },
          "strokeColor": {"type": "string"},
          "strokeWidth": {
            "type": ["number", "string"]
          },
          "fillMode": {
            "type": "string",
            "enum": ["none", "solid", "linear", "radial"]
          },
          "fillColorA": {"type": "string"},
          "fillColorB": {"type": "string"},
          "gradientAngle": {
            "type": ["number", "string"]
          },
          "text": {"type": "string"},
          "color": {"type": "string"},
          "fontFamily": {"type": "string"},
          "fontSize": {
            "type": ["number", "string"]
          },
          "fontWeight": {
            "type": "string",
            "enum": ["normal", "bold"]
          },
          "fontStyle": {
            "type": "string",
            "enum": ["normal", "italic"]
          }
        }
      }
    }
  }
];
