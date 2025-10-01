package com.segadb;

public class CharacterData {
    private String name;
    private String image;
    private String color;
    private String game;

    public CharacterData(String name, String image, String color, String game) {
        this.name = name;
        this.image = image;
        this.color = color;
        this.game = game;
    }

    public String getName() { return name; }
    public String getImage() { return image; }
    public String getColor() { return color; }
    public String getGame() { return game; }
}
