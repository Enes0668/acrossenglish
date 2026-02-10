import '../models/content_model.dart';

class ContentRepository {
  static final List<ContentModel> allContent = [
    // --- BEGINNER (A1-A2) ---
    // Series
    ContentModel(
      id: 'beg_ser_01',
      title: 'Extra English',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BNMjA5ODU3MTItNmYzMy00MzgwLWEyYTItODAyYzY0YTk0ODU0XkEyXkFqcGdeQXVyNTA4NzY1MzY@._V1_.jpg',
      type: 'series',
      level: 'Beginner',
    ),
    ContentModel(
      id: 'beg_ser_02',
      title: 'Peppa Pig',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BZjFkNDI4YC1hMmYwL002ZDM3LWE0OWMtMjg2Y2Q4YzE0NGYyXkEyXkFqcGdeQXVyNTgyNTA4MjM@._V1_FMjpg_UX1000_.jpg',
      type: 'series',
      level: 'Beginner',
    ),
     ContentModel(
      id: 'beg_ser_03',
      title: 'Dora the Explorer',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BOTMyNmZkN2MtZmMxMy00ZWNlLThlMTYtYKk2NzU1NzRhMjFhXkEyXkFqcGdeQXVyNjExODE1MDc@._V1_.jpg',
      type: 'series',
      level: 'Beginner',
    ),
    ContentModel(
      id: 'beg_ser_04',
      title: 'The Good Place',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BYjUyZWZkM2UtMzYxYy00ZmU3LWE0NmQtOGJjZDQ2ZmQwZmI4XkEyXkFqcGdeQXVyNjY1MTg4Mzc@._V1_.jpg',
      type: 'series',
      level: 'Beginner',
    ),
    ContentModel(
      id: 'beg_ser_05',
      title: 'Grace and Frankie',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BODQ2MDM1MjItZjFhNy00NDBkLTg0OTItZDRlZjdjNmEyIGYwXkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
      type: 'series',
      level: 'Beginner',
    ),
    
    // Books
    ContentModel(
      id: 'beg_bk_01',
      title: 'The Little Prince',
      imageUrl: 'https://m.media-amazon.com/images/I/71OZyJBkd+L._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Beginner',
    ),
    ContentModel(
      id: 'beg_bk_02',
      title: 'Charlotte\'s Web',
      imageUrl: 'https://m.media-amazon.com/images/I/91pI+-r+j4L._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Beginner',
    ),
    ContentModel(
      id: 'beg_bk_03',
      title: 'Peter Pan',
      imageUrl: 'https://m.media-amazon.com/images/I/91Jm3O7-cEL._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Beginner',
    ),
    ContentModel(
      id: 'beg_bk_04',
      title: 'Winnie-the-Pooh',
      imageUrl: 'https://m.media-amazon.com/images/I/91+q+Q-eRRL._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Beginner',
    ),
    ContentModel(
      id: 'beg_bk_05',
      title: 'The Cat in the Hat',
      imageUrl: 'https://m.media-amazon.com/images/I/81z7E0uWdtL._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Beginner',
    ),


    // --- INTERMEDIATE (B1-B2) ---
    // Series
    ContentModel(
      id: 'int_ser_01',
      title: 'Friends',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BNDVkYjU0MzctMzg1YS00NzE3LWhhYWQtMTRmZTE3NjA5YzdhXkEyXkFqcGdeQXVyMTEyMjM2NDc2._V1_FMjpg_UX1000_.jpg',
      type: 'series',
      level: 'Intermediate',
    ),
    ContentModel(
      id: 'int_ser_02',
      title: 'Modern Family',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BNzMzMjMkMxAtMmQzZS00Mzc1LTg0OWItNTY0YTMxMWRiM2FjXkEyXkFqcGdeQXVyNTA4NzY1MzY@._V1_FMjpg_UX1000_.jpg',
      type: 'series',
      level: 'Intermediate',
    ),
    ContentModel(
      id: 'int_ser_03',
      title: 'How I Met Your Mother',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BNjg1MDQ5MjQ2N15BMl5BanBnXkFtZTgwNjI5NjY5MTE@._V1_FMjpg_UX1000_.jpg',
      type: 'series',
      level: 'Intermediate',
    ),
    ContentModel(
      id: 'int_ser_04',
      title: 'Stranger Things',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BMjEzMDAxOTUyMV5BMl5BanBnXkFtZTgwNzAxMzYzOTE@._V1_.jpg',
      type: 'series',
      level: 'Intermediate',
    ),
    ContentModel(
      id: 'int_ser_05',
      title: 'The Big Bang Theory',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BY2FmZTY5YWUtMzIwMC00OWVhLThkMDEtZjMxYzExZTA2ODY1XkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_FMjpg_UX1000_.jpg',
      type: 'series',
      level: 'Intermediate',
    ),

    // Books
    ContentModel(
      id: 'int_bk_01',
      title: 'Harry Potter',
      imageUrl: 'https://m.media-amazon.com/images/I/71-++hbbERL._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Intermediate',
    ),
    ContentModel(
      id: 'int_bk_02',
      title: 'The Hunger Games',
      imageUrl: 'https://m.media-amazon.com/images/I/61I24wOsn8L._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Intermediate',
    ),
    ContentModel(
      id: 'int_bk_03',
      title: 'Percy Jackson & The Olympians',
      imageUrl: 'https://m.media-amazon.com/images/I/91+-e+W-l+L._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Intermediate',
    ),
     ContentModel(
      id: 'int_bk_04',
      title: 'Diary of a Wimpy Kid',
      imageUrl: 'https://m.media-amazon.com/images/I/71I0+4yZylL._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Intermediate',
    ),
    ContentModel(
      id: 'int_bk_05',
      title: 'The Giver',
      imageUrl: 'https://m.media-amazon.com/images/I/71E+9+U+P+L._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Intermediate',
    ),

    // --- ADVANCED (C1-C2) ---
    // Series
    ContentModel(
      id: 'adv_ser_01',
      title: 'Sherlock',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BMWY3NTljMjEtYzRiMi00NWM2LTkzNjItAwYzZjE3ODI3NjE3XkEyXkFqcGdeQXVyMjYwNDA2MDE@._V1_.jpg',
      type: 'series',
      level: 'Advanced',
    ),
    ContentModel(
      id: 'adv_ser_02',
      title: 'The Crown',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BODk0OWMwOTMtNDUyOC00MzdjLWEwOTAtMzRjZWM1NjFhYzI0XkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
      type: 'series',
      level: 'Advanced',
    ),
    ContentModel(
      id: 'adv_ser_03',
      title: 'Black Mirror',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BYTM3YWVhMDMtNjczMy00NGEyLWJhZDctYjNhMTRkNDE0ZTI1XkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_FMjpg_UX1000_.jpg',
      type: 'series',
      level: 'Advanced',
    ),
     ContentModel(
      id: 'adv_ser_04',
      title: 'Breaking Bad',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BODFhZjAwNjEtZDFjNi00ZTEyLWEzNjItOTgzZDNkNTc2ZGJiXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_FMjpg_UX1000_.jpg',
      type: 'series',
      level: 'Advanced',
    ),
    ContentModel(
      id: 'adv_ser_05',
      title: 'House of Cards',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BODM1MDU2NjY5NF5BMl5BanBnXkFtZTgwMDkxNwIzNjM@._V1_FMjpg_UX1000_.jpg',
      type: 'series',
      level: 'Advanced',
    ),

    // Books
    ContentModel(
      id: 'adv_bk_01',
      title: '1984',
      imageUrl: 'https://m.media-amazon.com/images/I/71rpa1-kyvL._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Advanced',
    ),
    ContentModel(
      id: 'adv_bk_02',
      title: 'The Great Gatsby',
      imageUrl: 'https://m.media-amazon.com/images/I/81af+MCATTL._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Advanced',
    ),
    ContentModel(
      id: 'adv_bk_03',
      title: 'Pride and Prejudice',
      imageUrl: 'https://m.media-amazon.com/images/I/71Q1tPupKjL._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Advanced',
    ),
    ContentModel(
      id: 'adv_bk_04',
      title: 'To Kill a Mockingbird',
      imageUrl: 'https://m.media-amazon.com/images/I/81gepf1eMqL._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Advanced',
    ),
     ContentModel(
      id: 'adv_bk_05',
      title: 'Sapiens',
      imageUrl: 'https://m.media-amazon.com/images/I/713jIoMO3UL._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Advanced',
    ),
  ];
}
