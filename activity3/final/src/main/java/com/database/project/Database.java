package com.database.project;

import java.sql.*;
import java.util.ArrayList;

public class Database {

    static final String dbUrl = "jdbc:mysql://localhost:3306/version1?useUnicode=true&characterEncoding=utf-8&serverTimezone=GMT%2B8";
    static final String user = "root";
    static final String password = "";
    static Connection conn = null;
    static PreparedStatement  insertUserStat = null;
    static PreparedStatement insertPlayerStat = null;
    static PreparedStatement insertCardStat = null;
    static PreparedStatement insertHasCardStat = null;
    static String insertUser = "insert into users value(?,?,?,?,?)";
    static String insertPlayer = "insert into players value(?,?,?,?,?,?)";
    static String insertCard = "insert into cards value(?,?,?,?,?)";
    static String insertHasCard = "insert into has_card value(?,?,?)";
    static long cardId = 0;
    boolean open () {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(dbUrl, user, password);
            return true;
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
            return false;
        } catch (SQLException e) {
            e.printStackTrace();
            this.close();
            return false;
        }
    }

    boolean openUserStat() {
        try {
            insertUserStat = conn.prepareStatement(insertUser);
            return true;
        } catch (SQLException e) {
            e.printStackTrace();
            this.close();
            return false;
        }
    }
    boolean openCardStat() {
        try {
            insertCardStat = conn.prepareStatement(insertCard);
            return true;
        } catch (SQLException e) {
            e.printStackTrace();
            this.close();
            return false;
        }
    }
    boolean openPlayerStat() {
        try {
            insertPlayerStat = conn.prepareStatement(insertPlayer);
            return true;
        } catch (SQLException e) {
            e.printStackTrace();
            this.close();
            return false;
        }
    }

    boolean openHasCardStat() {
        try {
            insertHasCardStat = conn.prepareStatement(insertHasCard);
            return true;
        } catch (SQLException e) {
            e.printStackTrace();
            this.close();
            return false;
        }
    }
    void close() {
        try{
            if (insertUserStat != null) {
                insertUserStat.close();
            }
            if (insertCardStat != null){
                insertCardStat.close();
            }
            if (insertPlayerStat != null) {
                insertPlayerStat.close();
            }
            if (conn != null) {
                conn.close();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    void createPlayer(String name, String nickname) {
        try {
            insertPlayerStat.setString(1, name);
            insertPlayerStat.setLong(2, 0);
            insertPlayerStat.setInt(3, 0);
            insertPlayerStat.setBoolean(4, false);
            insertPlayerStat.setString(5, nickname);
            insertPlayerStat.setInt(6, 0);
            insertPlayerStat.execute();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    void createUser(String name) {
        try {
            insertUserStat.setString(1, name);
            insertUserStat.setString(2, "");
            insertUserStat.setInt(3, 0);
            insertUserStat.setString(4, "");
            insertUserStat.setString(5, "");
            insertUserStat.execute();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    long createCards(String name) {
        try {
            insertCardStat.setString(1, null);
            insertCardStat.setString(2, "");
            insertCardStat.setString(3, name);
            insertCardStat.setInt(4, 2);
            insertCardStat.setString(5, "");
            insertCardStat.execute();
            cardId ++;
            return cardId;
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }
    void createHasCards(String owner, Long cardId, Integer num) {
        try {
            insertHasCardStat.setString(1, owner);
            insertHasCardStat.setLong(2, cardId);
            insertHasCardStat.setInt(3, num);
            insertHasCardStat.execute();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    ArrayList<String> getPlayers() {
        try {
            Statement statement = conn.createStatement();
            ResultSet resultSet = statement.executeQuery("select name from users");
            ArrayList res = new ArrayList();
            while (resultSet.next()) {
                res.add(resultSet.getString(1));
            }
            return res;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    ArrayList<Long> getIds() {
        try {
            Statement statement = conn.createStatement();
            ResultSet resultSet = statement.executeQuery("select id from cards");
            ArrayList res = new ArrayList();
            while (resultSet.next()) {
                res.add(resultSet.getLong(1));
            }
            return res;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}
