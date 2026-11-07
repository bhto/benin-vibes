import 'package:flutter/material.dart';

import 'package:benin_vibes/data.dart';

const testLyrics = [
  LyricLine(Duration.zero, 'La nuit tombe sur Cotonou'),
  LyricLine(Duration(seconds: 16), 'Les lampions s\'allument'),
  LyricLine(Duration(seconds: 34), 'Zinli dans les haut-parleurs'),
];

const testGenres = [
  Genre(
    id: 1,
    slug: 'afropop',
    name: 'Afropop',
    color: Color(0xFFE0447C),
    icon: Icons.album_rounded,
  ),
  Genre(
    id: 2,
    slug: 'gospel',
    name: 'Gospel',
    color: Color(0xFF6A4CFF),
    icon: Icons.church_rounded,
  ),
];

const testArtists = [
  Artist(id: 1, slug: 'sessime', name: 'Sessimè', tint: Color(0xFFE0447C)),
  Artist(id: 2, slug: 'fanicko', name: 'Fanicko', tint: Color(0xFF4E77B8)),
  Artist(id: 3, slug: 'zeynab', name: 'Zeynab', tint: Color(0xFF8B5CF6)),
];

const testTracks = [
  Track(
    id: 'zinli_night',
    title: 'Zinli Night',
    artist: 'Sessimè',
    artistSlug: 'sessime',
    genre: 'Afropop',
    genreSlug: 'afropop',
    audioPath: 'audio/zinli_night.mp3',
    duration: Duration(minutes: 3, seconds: 58),
    tint: Color(0xFFE0447C),
    lyrics: testLyrics,
    lyricsSynced: true,
  ),
  Track(
    id: 'cotonou_vibes',
    title: 'Cotonou Vibes',
    artist: 'Fanicko',
    artistSlug: 'fanicko',
    genre: 'Afropop',
    genreSlug: 'afropop',
    audioPath: 'audio/cotonou_vibes.mp3',
    duration: Duration(minutes: 3, seconds: 42),
    tint: Color(0xFF4E77B8),
  ),
  Track(
    id: 'gbe_mi',
    title: 'Gbè Mi',
    artist: 'Zeynab',
    artistSlug: 'zeynab',
    genre: 'Gospel',
    genreSlug: 'gospel',
    audioPath: 'audio/gbe_mi.mp3',
    duration: Duration(minutes: 3, seconds: 51),
    tint: Color(0xFF8B5CF6),
  ),
];

Library buildTestLibrary() =>
    const Library(artists: testArtists, genres: testGenres, tracks: testTracks);

Track buildTestTrack({
  String id = 'inédit',
  String title = 'Inédit',
  String artist = 'Artiste test',
}) {
  return Track(
    id: id,
    title: title,
    artist: artist,
    artistSlug: 'artiste_test',
    genre: 'Afropop',
    genreSlug: 'afropop',
    audioPath: 'audio/$id.mp3',
    duration: const Duration(minutes: 3, seconds: 30),
  );
}
