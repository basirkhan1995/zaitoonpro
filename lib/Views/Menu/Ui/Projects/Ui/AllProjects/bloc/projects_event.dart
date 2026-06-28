part of 'projects_bloc.dart';

sealed class ProjectsEvent extends Equatable {
  const ProjectsEvent();
}

class AddProjectEvent extends ProjectsEvent {
  final ProjectsModel newData;
  const AddProjectEvent(this.newData);
  @override
  List<Object?> get props => [newData];
}

class UpdateProjectEvent extends ProjectsEvent {
  final ProjectsModel newData;
  const UpdateProjectEvent(this.newData);
  @override
  List<Object?> get props => [newData];
}

class DeleteProjectEvent extends ProjectsEvent {
  final int pjrId;
  final String usrName;
  const DeleteProjectEvent(this.pjrId,this.usrName);
  @override
  List<Object?> get props => [pjrId,usrName];
}

class LoadProjectsEvent extends ProjectsEvent {
  final int? prjId;
  final String? search;
  final int? status;
  const LoadProjectsEvent({this.prjId,this.search,this.status});
  @override
  List<Object?> get props => [prjId,search,status];
}
