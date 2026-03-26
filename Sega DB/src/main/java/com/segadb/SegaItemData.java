package com.segadb;

public class SegaItemData {
    private final String name;
    private final String image;
    private final String color;
    private final String game;
    private final String type;

    public SegaItemData(String name, String image, String color, String game, String type) {
        this.name = name;
        this.image = image;
        this.color = color;
        this.game = game;
        this.type = type;
    }

    public String getName() { return name; }
    public String getImage() { return image; }
    public String getColor() { return color; }
    public String getGame() { return game; }
    public String getType() { return type; }
}
