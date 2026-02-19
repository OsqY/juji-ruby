class ProjectsController < ApplicationController
  before_action :set_project, only: %i[ destroy ]

  def index
    @projects = current_user.projects.includes(:project_tasks).order(created_at: :desc)
    @new_project = current_user.projects.build
  end

  def create
    @project = current_user.projects.build(project_params)
    if @project.save
      redirect_to projects_path, notice: "Proyecto creado / Project created."
    else
      @projects = current_user.projects.includes(:project_tasks).order(created_at: :desc)
      @new_project = @project
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Proyecto eliminado / Project deleted."
  end

  private

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :target_date)
  end
end
