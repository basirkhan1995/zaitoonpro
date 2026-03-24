// backup_bloc.dart
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

part 'backup_event.dart';
part 'backup_state.dart';

class BackupBloc extends Bloc<BackupEvent, BackupState> {
  final Repositories _repo;
  BackupBloc(this._repo) : super(BackupInitial()) {
    on<DownloadBackupEvent>(_onDownloadBackup);
    on<LoadBackupsEvent>(_onLoadBackups);
    on<DeleteBackupEvent>(_onDeleteBackup);
  }

  Future<void> _onDownloadBackup(
      DownloadBackupEvent event,
      Emitter<BackupState> emit,
      ) async {
    emit(BackupLoading());
    try {
      await _repo.downloadBackup();
      final backups = await _repo.getBackupFiles();
      emit(BackupsLoaded(backups));
    } catch (e) {
      emit(BackupError(e.toString()));
    }
  }


  Future<void> _onLoadBackups(
      LoadBackupsEvent event,
      Emitter<BackupState> emit,
      ) async {
    emit(BackupLoading());
    try {
      final backups = await _repo.getBackupFiles();
      emit(BackupsLoaded(backups));
    } catch (e) {
      emit(BackupError(e.toString()));
    }
  }

  Future<void> _onDeleteBackup(
      DeleteBackupEvent event,
      Emitter<BackupState> emit,
      ) async {
    emit(BackupLoading());
    try {
      await _repo.deleteBackup(event.filePath);
      final backups = await _repo.getBackupFiles();
      emit(BackupsLoaded(backups));
    } catch (e) {
      emit(BackupError(e.toString()));
    }
  }
}