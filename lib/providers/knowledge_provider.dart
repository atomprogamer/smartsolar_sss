import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/knowledge_model.dart';

/// Provider class for managing knowledge base data
class KnowledgeProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<KnowledgeBaseModel> _articles = [];
  List<KnowledgeBaseModel> _featuredArticles = [];
  List<ConsultationModel> _userConsultations = [];
  List<ConsultationModel> _consultationsByExpert = [];
  bool _isLoading = false;
  String? _error;

  /// Get all articles
  List<KnowledgeBaseModel> get articles => _articles;

  /// Get featured articles
  List<KnowledgeBaseModel> get featuredArticles => _featuredArticles;

  /// Get user consultations
  List<ConsultationModel> get userConsultations => _userConsultations;

  /// Get solar basics articles
  List<KnowledgeBaseModel> get solarBasicsArticles => _articles.where((article) => 
      article.category == ArticleCategory.solarBasics).toList();

  /// Get installation articles
  List<KnowledgeBaseModel> get installationArticles => _articles.where((article) => 
      article.category == ArticleCategory.installation).toList();

  /// Get maintenance articles
  List<KnowledgeBaseModel> get maintenanceArticles => _articles.where((article) => 
      article.category == ArticleCategory.maintenance).toList();

  /// Get troubleshooting articles
  List<KnowledgeBaseModel> get troubleshootingArticles => _articles.where((article) => 
      article.category == ArticleCategory.troubleshooting).toList();

  /// Get product guides articles
  List<KnowledgeBaseModel> get productGuidesArticles => _articles.where((article) => 
      article.category == ArticleCategory.productGuides).toList();

  /// Get energy saving articles
  List<KnowledgeBaseModel> get energySavingArticles => _articles.where((article) => 
      article.category == ArticleCategory.energySaving).toList();

  /// Get pending consultations
  List<ConsultationModel> get pendingConsultations => _userConsultations.where((consultation) => 
      consultation.isPending).toList();

  /// Get confirmed consultations
  List<ConsultationModel> get confirmedConsultations => _userConsultations.where((consultation) => 
      consultation.isConfirmed).toList();

  /// Get completed consultations
  List<ConsultationModel> get completedConsultations => _userConsultations.where((consultation) => 
      consultation.isCompleted).toList();

  /// Get consultations by expert (expert only)
  List<ConsultationModel> get consultationsByExpert => _consultationsByExpert;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Get error message
  String? get error => _error;

  /// Fetch all articles
  Future<void> fetchArticles() async {
    try {
      _isLoading = true;
      notifyListeners();

      final articlesSnapshot = await _firestore.collection('knowledgeBase').get();

      _articles = articlesSnapshot.docs.map((doc) => KnowledgeBaseModel.fromSnapshot(doc)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch featured articles
  Future<void> fetchFeaturedArticles() async {
    try {
      _isLoading = true;
      notifyListeners();

      final articlesSnapshot = await _firestore.collection('knowledgeBase')
          .where('featured', isEqualTo: true)
          .limit(5)
          .get();

      _featuredArticles = articlesSnapshot.docs.map((doc) => KnowledgeBaseModel.fromSnapshot(doc)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch articles by category
  Future<List<KnowledgeBaseModel>> fetchArticlesByCategory(ArticleCategory category) async {
    try {
      _isLoading = true;
      notifyListeners();

      final categoryString = category.toString().split('.').last;

      final articlesSnapshot = await _firestore.collection('knowledgeBase')
          .where('category', isEqualTo: categoryString)
          .get();

      final categoryArticles = articlesSnapshot.docs.map((doc) => KnowledgeBaseModel.fromSnapshot(doc)).toList();

      _isLoading = false;
      notifyListeners();

      return categoryArticles;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return [];
    }
  }

  /// Get article by ID
  Future<KnowledgeBaseModel?> getArticleById(String articleId) async {
    try {
      // First check if the article is already in the local list
      final localArticle = _articles.firstWhere(
        (article) => article.id == articleId,
        orElse: () => KnowledgeBaseModel.empty(),
      );

      if (localArticle.id.isNotEmpty) {
        return localArticle;
      }

      _isLoading = true;
      notifyListeners();

      final articleDoc = await _firestore.collection('knowledgeBase').doc(articleId).get();

      _isLoading = false;
      notifyListeners();

      if (!articleDoc.exists) {
        return null;
      }

      return KnowledgeBaseModel.fromSnapshot(articleDoc);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return null;
    }
  }

  /// Search articles by title or content
  Future<List<KnowledgeBaseModel>> searchArticles(String query) async {
    try {
      _isLoading = true;
      notifyListeners();

      final queryLower = query.toLowerCase();

      // First try to fetch from local list
      if (_articles.isNotEmpty) {
        final results = _articles.where((article) => 
            article.title.toLowerCase().contains(queryLower) || 
            article.content.toLowerCase().contains(queryLower)).toList();

        _isLoading = false;
        notifyListeners();

        return results;
      }

      // If local list is empty, fetch from Firestore
      final articlesSnapshot = await _firestore.collection('knowledgeBase').get();
      final allArticles = articlesSnapshot.docs.map((doc) => KnowledgeBaseModel.fromSnapshot(doc)).toList();

      final results = allArticles.where((article) => 
          article.title.toLowerCase().contains(queryLower) || 
          article.content.toLowerCase().contains(queryLower)).toList();

      _isLoading = false;
      notifyListeners();

      return results;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return [];
    }
  }

  /// Fetch user consultations
  Future<void> fetchUserConsultations() async {
    try {
      if (_auth.currentUser == null) {
        return;
      }

      _isLoading = true;
      notifyListeners();

      final consultationsSnapshot = await _firestore.collection('consultations')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('consultationDate', descending: true)
          .get();

      _userConsultations = consultationsSnapshot.docs.map((doc) => ConsultationModel.fromSnapshot(doc)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch all consultations (admin/expert only)
  Future<List<ConsultationModel>> fetchAllConsultations() async {
    try {
      _isLoading = true;
      notifyListeners();

      final consultationsSnapshot = await _firestore.collection('consultations')
          .orderBy('consultationDate', descending: true)
          .get();

      final allConsultations = consultationsSnapshot.docs.map((doc) => ConsultationModel.fromSnapshot(doc)).toList();

      _isLoading = false;
      notifyListeners();

      return allConsultations;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return [];
    }
  }

  /// Fetch consultations by expert (expert only)
  Future<void> fetchConsultationsByExpert(String expertId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final consultationsSnapshot = await _firestore.collection('consultations')
          .where('expertId', isEqualTo: expertId)
          .orderBy('consultationDate', descending: true)
          .get();

      _consultationsByExpert = consultationsSnapshot.docs.map((doc) => ConsultationModel.fromSnapshot(doc)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get consultation by ID
  Future<ConsultationModel?> getConsultationById(String consultationId) async {
    try {
      // First check if the consultation is already in the local list
      final localConsultation = _userConsultations.firstWhere(
        (consultation) => consultation.id == consultationId,
        orElse: () => ConsultationModel.empty(),
      );

      if (localConsultation.id.isNotEmpty) {
        return localConsultation;
      }

      _isLoading = true;
      notifyListeners();

      final consultationDoc = await _firestore.collection('consultations').doc(consultationId).get();

      _isLoading = false;
      notifyListeners();

      if (!consultationDoc.exists) {
        return null;
      }

      return ConsultationModel.fromSnapshot(consultationDoc);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return null;
    }
  }

  /// Request consultation
  Future<bool> requestConsultation({
    required String expertId,
    required DateTime consultationDate,
    required String duration,
    String? notes,
    String? topic,
    String? userQuestions,
  }) async {
    try {
      if (_auth.currentUser == null) {
        _error = 'User not logged in';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      notifyListeners();

      final consultationRef = _firestore.collection('consultations').doc();

      final newConsultation = ConsultationModel(
        id: consultationRef.id,
        userId: _auth.currentUser!.uid,
        expertId: expertId,
        consultationDate: consultationDate,
        duration: duration,
        notes: notes,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        topic: topic,
        userQuestions: userQuestions,
      );

      await consultationRef.set(newConsultation.toMap());

      // Add to local list
      _userConsultations.add(newConsultation);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Cancel consultation
  Future<bool> cancelConsultation(String consultationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('consultations').doc(consultationId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _userConsultations.indexWhere((consultation) => consultation.id == consultationId);
      if (index != -1) {
        _userConsultations[index] = _userConsultations[index].copyWith(
          status: 'cancelled',
          updatedAt: DateTime.now(),
        );
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Update consultation status (expert only)
  Future<bool> updateConsultationStatus(String consultationId, String status) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('consultations').doc(consultationId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      // Update local list if it's a user consultation
      final index = _userConsultations.indexWhere((consultation) => consultation.id == consultationId);
      if (index != -1) {
        _userConsultations[index] = _userConsultations[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Add expert response to consultation (expert only)
  Future<bool> addExpertResponse(String consultationId, String response) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('consultations').doc(consultationId).update({
        'expertResponse': response,
        'status': 'completed',
        'updatedAt': Timestamp.now(),
      });

      // Update local list if it's a user consultation
      final index = _userConsultations.indexWhere((consultation) => consultation.id == consultationId);
      if (index != -1) {
        _userConsultations[index] = _userConsultations[index].copyWith(
          expertResponse: response,
          status: 'completed',
          updatedAt: DateTime.now(),
        );
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Add article (admin/expert only)
  Future<bool> addArticle(KnowledgeBaseModel article) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docRef = _firestore.collection('knowledgeBase').doc();
      final newArticle = article.copyWith(id: docRef.id);

      await docRef.set(newArticle.toMap());

      // Add to local list
      _articles.add(newArticle);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Update article (admin/expert only)
  Future<bool> updateArticle(KnowledgeBaseModel article) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('knowledgeBase').doc(article.id).update(article.toMap());

      // Update local list
      final index = _articles.indexWhere((a) => a.id == article.id);
      if (index != -1) {
        _articles[index] = article;
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Delete article (admin/expert only)
  Future<bool> deleteArticle(String articleId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('knowledgeBase').doc(articleId).delete();

      // Remove from local list
      _articles.removeWhere((article) => article.id == articleId);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
