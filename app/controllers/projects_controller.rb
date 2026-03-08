class ProjectsController < ApplicationController
  before_action :set_project, only: %i[ destroy ]

  def index
    load_index_data
  end

  def create
    @project = current_user.projects.build(project_params)

    if @project.save
      load_index_data

      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Proyecto creado / Project created."
          render_projects_content
        end
        format.html { redirect_to projects_path, notice: "Proyecto creado / Project created." }
      end
    else
      load_index_data(new_project: @project)

      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = @project.errors.full_messages.to_sentence.presence || "No se pudo crear el proyecto."
          render_projects_content(status: :unprocessable_entity)
        end
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project.destroy
    load_index_data

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Proyecto eliminado / Project deleted."
        render_projects_content
      end
      format.html { redirect_to projects_path, notice: "Proyecto eliminado / Project deleted." }
    end
  end

  private

  def load_index_data(new_project: nil)
    @projects = current_user.projects.includes(:project_tasks).order(created_at: :desc)
    @new_project = new_project || current_user.projects.build
  end

  def render_projects_content(status: :ok)
    render turbo_stream: turbo_stream.replace("projects_content", partial: "projects/content"), status: status
  end

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :target_date)
  end
end
