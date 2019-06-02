package com.database.project;

/**
 * Hello world!
 *
 */
public class App
{
    public static void main( String[] args )
    {
        Generator generator = new Generator(true);
        generator.generateCards(50);
        generator.close();
    }
}
