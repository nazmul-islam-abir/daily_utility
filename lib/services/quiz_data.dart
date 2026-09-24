import 'package:flutter/material.dart';

/// A single quiz question with 4 options and one correct index.
class QuizQuestion {
  final String questionBn;
  final String questionEn;
  final List<String> optionsBn;
  final List<String> optionsEn;
  final int correctIndex;
  final String hintBn;
  final String hintEn;
  final IconData icon;

  const QuizQuestion({
    required this.questionBn,
    required this.questionEn,
    required this.optionsBn,
    required this.optionsEn,
    required this.correctIndex,
    required this.hintBn,
    required this.hintEn,
    this.icon = Icons.psychology_outlined,
  });
}

/// 10-question daily reflection quiz. Bangla + English parallel.
const kQuizQuestions = [
  QuizQuestion(
    questionBn: 'নতুকা সম্পর্কে সবচেয়ে প্রাচীন জ্ঞাত তথ্য কোন দেশে পাওয়া গেছে?',
    questionEn: 'Where was the earliest known evidence of cotton found?',
    optionsBn: ['মিশর', 'ভারত', 'চীন', 'পেরু'],
    optionsEn: ['Egypt', 'India', 'China', 'Peru'],
    correctIndex: 3,
    hintBn: 'দক্ষিণ আমেরিকার সভ্যতা',
    hintEn: 'A South American civilisation',
    icon: Icons.eco_outlined,
  ),
  QuizQuestion(
    questionBn: 'মানবদেহের সবচেয়ে বড় অঙ্গ কোনটি?',
    questionEn: 'What is the largest organ in the human body?',
    optionsBn: ['যকৃত', 'ত্বক', 'ফুসফুস', 'হৃদপিণ্ড'],
    optionsEn: ['Liver', 'Skin', 'Lungs', 'Heart'],
    correctIndex: 1,
    hintBn: 'এটি আপনার পুরো শরীরকে ঢেকে রাখে',
    hintEn: 'It covers your entire body',
    icon: Icons.face_outlined,
  ),
  QuizQuestion(
    questionBn: 'একটি অক্টোপাসের কতটি হৃদপিণ্ড থাকে?',
    questionEn: 'How many hearts does an octopus have?',
    optionsBn: ['১', '২', '৩', '৪'],
    optionsEn: ['1', '2', '3', '4'],
    correctIndex: 2,
    hintBn: 'তিনটি — দুটি ফুলকার জন্য',
    hintEn: 'Three — two for the gills',
    icon: Icons.set_meal_outlined,
  ),
  QuizQuestion(
    questionBn: 'সূর্য পৃথিবীর চারদিকে একবার ঘুরতে কত সময় নেয়?',
    questionEn: 'How long does the Sun take to orbit the galaxy?',
    optionsBn: ['২৫০ মিলিয়ন বছর', '১ বছর', '২৪ ঘণ্টা', '১০০০ বছর'],
    optionsEn: ['250 million years', '1 year', '24 hours', '1000 years'],
    correctIndex: 0,
    hintBn: 'একে কোসমিক ইয়ার বলা হয়',
    hintEn: 'It is called a cosmic year',
    icon: Icons.public_outlined,
  ),
  QuizQuestion(
    questionBn: 'বাংলা ভাষার প্রথম সাহিত্য কোনটি?',
    questionEn: 'What is the first major work of Bengali literature?',
    optionsBn: ['মেঘনাদবধ কাব্য', 'চর্যাপদ', 'শ্রীকৃষ্ণকীর্তন', 'পদ্মাবতী'],
    optionsEn: ['Meghnadbadh Kabya', 'Charyapada', 'Sri Krishna Kirtan', 'Padmavati'],
    correctIndex: 1,
    hintBn: '১০ম-১২শ শতকের বৌদ্ধ সহস্র গান',
    hintEn: '10-12th century Buddhist song cycle',
    icon: Icons.menu_book_outlined,
  ),
  QuizQuestion(
    questionBn: 'কোন গ্রহ সূর্যের সবচেয়ে কাছে?',
    questionEn: 'Which planet is closest to the Sun?',
    optionsBn: ['শুক্র', 'বুধ', 'মঙ্গল', 'পৃথিবী'],
    optionsEn: ['Venus', 'Mercury', 'Mars', 'Earth'],
    correctIndex: 1,
    hintBn: 'এটি সবচেয়ে ছোট গ্রহও',
    hintEn: 'It is also the smallest planet',
    icon: Icons.wb_sunny_outlined,
  ),
  QuizQuestion(
    questionBn: 'ঘুমের সময় মস্তিষ্ক কোন তরঙ্গ তৈরি করে?',
    questionEn: 'Which brain waves are prominent during deep sleep?',
    optionsBn: ['আলফা', 'বিটা', 'ডেল্টা', 'গামা'],
    optionsEn: ['Alpha', 'Beta', 'Delta', 'Gamma'],
    correctIndex: 2,
    hintBn: 'এগুলো সবচেয়ে ধীর তরঙ্গ',
    hintEn: 'These are the slowest waves',
    icon: Icons.bedtime_outlined,
  ),
  QuizQuestion(
    questionBn: 'এক কাপ কফিতে আনুমানিক কত মিলিগ্রাম ক্যাফেইন থাকে?',
    questionEn: 'About how much caffeine is in a single cup of coffee?',
    optionsBn: ['৯৫ মিলিগ্রাম', '৫ মিলিগ্রাম', '৫০০ মিলিগ্রাম', '০ মিলিগ্রাম'],
    optionsEn: ['95 mg', '5 mg', '500 mg', '0 mg'],
    correctIndex: 0,
    hintBn: 'দেড়শো ছবিও সরবরাহকারী ক্যাফে ক্লাসিক ডোজ',
    hintEn: 'A classic cafe-sized dose',
    icon: Icons.coffee_outlined,
  ),
  QuizQuestion(
    questionBn: 'পৃথিবীর বায়ুমণ্ডলে সবচেয়ে বেশি কোন গ্যাস আছে?',
    questionEn: 'Which gas is most abundant in Earth\'s atmosphere?',
    optionsBn: ['অক্সিজেন', 'নাইট্রোজেন', 'কার্বন ডাই অক্সাইড', 'আর্গন'],
    optionsEn: ['Oxygen', 'Nitrogen', 'Carbon dioxide', 'Argon'],
    correctIndex: 1,
    hintBn: 'প্রায় ৭৮%',
    hintEn: 'Around 78%',
    icon: Icons.air_outlined,
  ),
  QuizQuestion(
    questionBn: 'মানুষের হৃদপিণ্ড প্রতিদিন প্রায় কতবার স্পন্দিত হয়?',
    questionEn: 'About how many times does a human heart beat each day?',
    optionsBn: ['১,০০০', '১,০০,০০০', '১০,০০০', '১০০,০০০'],
    optionsEn: ['1,000', '100,000', '10,000', '1,000,000'],
    correctIndex: 1,
    hintBn: 'পাঁচ-সংখ্যার একটি সংখ্যা',
    hintEn: 'A five-digit number',
    icon: Icons.favorite_outline,
  ),
];
