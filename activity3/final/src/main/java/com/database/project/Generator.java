package com.database.project;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Random;

public class Generator {
    private ArrayList<String> dict = new ArrayList<>(5000);
    private ArrayList<String> names = new ArrayList<>();
    private ArrayList<Long> ids = new ArrayList<>();
    private Database database = new Database();
    public Generator() {
        this.setup(false);
    }

    public Generator(boolean flag) {
        this.setup(flag);
    }
    private void setup(boolean flag) {
        try {
            String file = "dictionary.txt";
            BufferedReader reader = new BufferedReader(new FileReader(file));
            String word;
            while ((word = reader.readLine()) != null) {
                dict.add(word);
            }
            database.open();
            if (flag) {
              this.names = database.getPlayers();
              this.ids = database.getIds();
              System.out.println(this.ids.size());
              System.out.println(this.names.size());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void generateUser(int num) {
        database.openUserStat();
        int i = 0;
        while (i < num) {
            String name = this.dict.get(i);
            database.createUser(name);
            this.names.add(name);
            i++;
        }
    }

    public void generatePlayer(int num) {
        database.openPlayerStat();
        int i = 0;
        Random random = new Random();
        int size = this.dict.size();
        while (i < num) {
            String name = this.names.get(i);
            database.createPlayer(name, this.dict.get(random.nextInt(size)));
            i++;
        }
    }

    public void generateCards(int num) {
        database.openCardStat();
        int i = 0;
        Random random = new Random();
        int size = this.dict.size();
        while (i < num) {
            String name = this.dict.get(i);
            long id = database.createCards(this.dict.get(random.nextInt(size)));
            this.ids.add(id);
            i++;
        }
    }

    public void generateHasCards() {
        database.openHasCardStat();
        Random random = new Random();
        int size = this.ids.size();
        HashSet<Long> existIds;
        for (String name: names) {
            existIds = new HashSet<>();
            int end = 20 + random.nextInt(30);
            for (int j = 0; j <end; j++) {
                Long id = this.ids.get(random.nextInt(size));
                if (!existIds.contains(id)) {
                    database.createHasCards(name,
                            id, random.nextInt(10));
                    existIds.add(id);
                }
            }
        }
    }

    public void generateAll(int usernum, int cardnum) {
        this.generateUser(usernum);
        this.generatePlayer(usernum);
        this.generateCards(cardnum);
        this.generateHasCards();
    }

    void close() {
        this.database.close();
    }
}
