import 'package:firebase_database/firebase_database.dart';
import 'package:musiva/core/utils/exception_handler.dart';
import 'package:musiva/core/utils/logger.dart';
import 'package:musiva/core/utils/retry_helper.dart';
import '../../domain/entities/song.dart';

class FirebaseDatabaseDataSource {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final int _pageSize = 10;
  static const String _tag = 'FirebaseDatabaseDataSource';

  // Save song data to Firebase Realtime Database with retry mechanism
  Future<void> saveSong(Map<String, dynamic> songData) async {
    try {
      log.i('$_tag: Saving song with ID: ${songData['id']}');
      final songRef = _database.ref().child('songs').child(songData['id']);
      
      // Use retry mechanism for saving song data
      await RetryHelper.retry(
        operation: () => songRef.set(songData),
        maxRetries: 3,
        retryDelay: 1000,
        onRetry: (exception, attempt, maxAttempts) {
          log.w('$_tag: Retrying song save (attempt $attempt/$maxAttempts) after error: ${exception.toString()}');
        },
      );
      
      log.i('$_tag: Song saved successfully');
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to save song: ${e.toString()}';
      log.e('$_tag: $errorMsg', e, stackTrace);
      throw Exception(errorMsg);
    }
  }

  // Get songs with pagination and retry mechanism
  Future<List<Map<String, dynamic>>> getSongs({
    int page = 1,
    String? sortBy,
    bool descending = true,
    String? searchQuery,
  }) async {
    try {
      log.i('$_tag: Getting songs - page: $page, sortBy: $sortBy, descending: $descending, searchQuery: $searchQuery');
      
      // Get all songs first (without ordering) to avoid index errors, with retry mechanism
      final snapshot = await RetryHelper.retry(
        operation: () => _database.ref().child('songs').get(),
        maxRetries: 3,
        retryDelay: 1000,
        onRetry: (exception, attempt, maxAttempts) {
          log.w('$_tag: Retrying songs fetch (attempt $attempt/$maxAttempts) after error');
        },
      );
      
      if (snapshot.exists) {
        List<Map<String, dynamic>> songs = [];
        
        // Convert to list for easier manipulation
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, value) {
          Map<String, dynamic> song = Map<String, dynamic>.from(value);
          songs.add(song);
        });
        
        log.d('$_tag: Retrieved ${songs.length} songs from database');
        
        // Apply search filter if provided
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          log.d('$_tag: Filtering songs by search query: $query');
          
          songs = songs.where((song) {
            return song['title'].toString().toLowerCase().contains(query) ||
                   song['artist'].toString().toLowerCase().contains(query);
          }).toList();
          
          log.d('$_tag: ${songs.length} songs match the search query');
        }
        
        // Sort the list in memory
        log.d('$_tag: Sorting songs by ${sortBy ?? 'createdAt'} ${descending ? 'descending' : 'ascending'}');
        if (sortBy != null) {
          songs.sort((a, b) {
            var aValue = a[sortBy];
            var bValue = b[sortBy];
            
            // Handle different data types
            if (aValue is String && bValue is String) {
              return descending 
                  ? bValue.compareTo(aValue) 
                  : aValue.compareTo(bValue);
            } else if (aValue is num && bValue is num) {
              return descending 
                  ? bValue.compareTo(aValue) 
                  : aValue.compareTo(bValue);
            } else if (aValue is String && bValue is num) {
              // Handle mixed types (convert to string)
              return descending 
                  ? bValue.toString().compareTo(aValue) 
                  : aValue.compareTo(bValue.toString());
            } else if (aValue is num && bValue is String) {
              // Handle mixed types (convert to string)
              return descending 
                  ? bValue.compareTo(aValue.toString()) 
                  : aValue.toString().compareTo(bValue);
            } else {
              return 0;
            }
          });
        } else {
          // Default sort by createdAt
          songs.sort((a, b) {
            String aCreatedAt = a['createdAt'] ?? '';
            String bCreatedAt = b['createdAt'] ?? '';
            return descending 
                ? bCreatedAt.compareTo(aCreatedAt) 
                : aCreatedAt.compareTo(bCreatedAt);
          });
        }
        
        // Apply pagination to the sorted/filtered list
        final startAt = (page - 1) * _pageSize;
        final endAt = startAt + _pageSize - 1;
        
        log.d('$_tag: Applying pagination - startAt: $startAt, endAt: $endAt');
        
        if (songs.length > startAt) {
          final endIndex = songs.length > endAt ? endAt + 1 : songs.length;
          final paginatedSongs = songs.sublist(startAt, endIndex);
          log.i('$_tag: Returning ${paginatedSongs.length} songs for page $page');
          return paginatedSongs;
        }
        
        log.i('$_tag: No songs available for page $page');
        return [];
      }
      
      log.i('$_tag: No songs found in database');
      return [];
    } catch (e, stackTrace) {
      final errorMsg = 'Error fetching songs: ${e.toString()}';
      log.e('$_tag: $errorMsg', e, stackTrace);
      // Return empty list instead of throwing to make the app more resilient
      return [];
    }
  }

  // Get featured songs (e.g., most played or recently added) with retry mechanism
  Future<List<Map<String, dynamic>>> getFeaturedSongs({int limit = 5}) async {
    try {
      log.i('$_tag: Getting featured songs with limit: $limit');
      
      // Get all songs and sort in memory to avoid index errors, with retry mechanism
      final snapshot = await RetryHelper.retry(
        operation: () => _database.ref().child('songs').get(),
        maxRetries: 3,
        retryDelay: 1000,
        onRetry: (exception, attempt, maxAttempts) {
          log.w('$_tag: Retrying featured songs fetch (attempt $attempt/$maxAttempts) after error');
        },
      );
      
      if (snapshot.exists) {
        List<Map<String, dynamic>> songs = [];
        
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, value) {
          Map<String, dynamic> song = Map<String, dynamic>.from(value);
          songs.add(song);
        });
        
        log.d('$_tag: Retrieved ${songs.length} songs for featured selection');
        
        // Sort by plays in descending order
        songs.sort((a, b) {
          int aPlays = a['plays'] is int ? a['plays'] : 0;
          int bPlays = b['plays'] is int ? b['plays'] : 0;
          return bPlays.compareTo(aPlays);
        });
        
        log.d('$_tag: Sorted songs by play count');
        
        // Take only the top 'limit' songs
        if (songs.length > limit) {
          final featuredSongs = songs.sublist(0, limit);
          log.i('$_tag: Returning $limit featured songs');
          return featuredSongs;
        }
        
        log.i('$_tag: Returning ${songs.length} featured songs (less than requested limit)');
        return songs;
      }
      
      log.i('$_tag: No songs found for featured selection');
      return [];
    } catch (e, stackTrace) {
      final errorMsg = 'Error fetching featured songs: ${e.toString()}';
      log.e('$_tag: $errorMsg', e, stackTrace);
      // Return empty list instead of throwing to make the app more resilient
      return [];
    }
  }

  // Get total number of songs (for pagination) with retry mechanism
  Future<int> getTotalSongs() async {
    try {
      log.i('$_tag: Getting total number of songs');
      
      // Use retry mechanism for getting total songs
      final snapshot = await RetryHelper.retry(
        operation: () => _database.ref().child('songs').get(),
        maxRetries: 3,
        retryDelay: 1000,
        onRetry: (exception, attempt, maxAttempts) {
          log.w('$_tag: Retrying total songs count (attempt $attempt/$maxAttempts) after error');
        },
      );
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        log.i('$_tag: Total songs count: ${values.length}');
        return values.length;
      }
      
      log.i('$_tag: No songs found in database');
      return 0;
    } catch (e, stackTrace) {
      final errorMsg = 'Error getting total songs: ${e.toString()}';
      log.e('$_tag: $errorMsg', e, stackTrace);
      return 0;
    }
  }

  // Increment play count for a song with retry mechanism
  Future<void> incrementPlayCount(String songId) async {
    try {
      log.i('$_tag: Incrementing play count for song ID: $songId');
      
      final songRef = _database.ref().child('songs').child(songId);
      
      // Use retry mechanism for getting current play count
      final snapshot = await RetryHelper.retry(
        operation: () => songRef.child('plays').get(),
        maxRetries: 2, // Lower retry count for non-critical operation
        retryDelay: 500,
        onRetry: (exception, attempt, maxAttempts) {
          log.w('$_tag: Retrying play count fetch (attempt $attempt/$maxAttempts) after error');
        },
      );
      
      if (snapshot.exists) {
        int currentPlays = 0;
        
        // Handle different data types
        if (snapshot.value is int) {
          currentPlays = snapshot.value as int;
        } else if (snapshot.value is String) {
          currentPlays = int.tryParse(snapshot.value as String) ?? 0;
        }
        
        log.d('$_tag: Current play count: $currentPlays');
        
        // Use retry mechanism for updating play count
        await RetryHelper.retry(
          operation: () => songRef.update({'plays': currentPlays + 1}),
          maxRetries: 2, // Lower retry count for non-critical operation
          retryDelay: 500,
          onRetry: (exception, attempt, maxAttempts) {
            log.w('$_tag: Retrying play count update (attempt $attempt/$maxAttempts) after error');
          },
        );
        
        log.i('$_tag: Play count incremented to ${currentPlays + 1}');
      } else {
        log.w('$_tag: Play count field does not exist for song ID: $songId');
      }
    } catch (e, stackTrace) {
      final errorMsg = 'Error incrementing play count: ${e.toString()}';
      log.e('$_tag: $errorMsg', e, stackTrace);
      // Silently fail - this is not critical functionality
    }
  }

  // Search songs by title or artist with retry mechanism
  Future<List<Map<String, dynamic>>> searchSongs(String query) async {
    try {
      log.i('$_tag: Searching songs with query: $query');
      
      // Use retry mechanism for searching songs
      final snapshot = await RetryHelper.retry(
        operation: () => _database.ref().child('songs').get(),
        maxRetries: 3,
        retryDelay: 1000,
        onRetry: (exception, attempt, maxAttempts) {
          log.w('$_tag: Retrying song search (attempt $attempt/$maxAttempts) after error');
        },
      );
      
      if (snapshot.exists) {
        List<Map<String, dynamic>> songs = [];
        final searchQuery = query.toLowerCase();
        
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, value) {
          Map<String, dynamic> song = Map<String, dynamic>.from(value);
          
          // Check if title or artist contains the search query
          if (song['title'].toString().toLowerCase().contains(searchQuery) ||
              song['artist'].toString().toLowerCase().contains(searchQuery)) {
            songs.add(song);
          }
        });
        
        log.d('$_tag: Found ${songs.length} songs matching query: $query');
        
        // Sort results by relevance (exact matches first, then partial matches)
        songs.sort((a, b) {
          final aTitle = a['title'].toString().toLowerCase();
          final bTitle = b['title'].toString().toLowerCase();
          final aArtist = a['artist'].toString().toLowerCase();
          final bArtist = b['artist'].toString().toLowerCase();
          
          // Exact title match gets highest priority
          if (aTitle == searchQuery && bTitle != searchQuery) return -1;
          if (bTitle == searchQuery && aTitle != searchQuery) return 1;
          
          // Exact artist match gets second priority
          if (aArtist == searchQuery && bArtist != searchQuery) return -1;
          if (bArtist == searchQuery && aArtist != searchQuery) return 1;
          
          // Title starts with query gets third priority
          if (aTitle.startsWith(searchQuery) && !bTitle.startsWith(searchQuery)) return -1;
          if (bTitle.startsWith(searchQuery) && !aTitle.startsWith(searchQuery)) return 1;
          
          // Artist starts with query gets fourth priority
          if (aArtist.startsWith(searchQuery) && !bArtist.startsWith(searchQuery)) return -1;
          if (bArtist.startsWith(searchQuery) && !aArtist.startsWith(searchQuery)) return 1;
          
          // Default to sorting by plays
          final aPlays = a['plays'] is int ? a['plays'] : 0;
          final bPlays = b['plays'] is int ? b['plays'] : 0;
          return bPlays.compareTo(aPlays);
        });
        
        log.i('$_tag: Returning ${songs.length} search results sorted by relevance');
        return songs;
      }
      
      log.i('$_tag: No songs found in database for search');
      return [];
    } catch (e, stackTrace) {
      final errorMsg = 'Error searching songs: ${e.toString()}';
      log.e('$_tag: $errorMsg', e, stackTrace);
      return [];
    }
  }
}