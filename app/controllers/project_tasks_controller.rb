class ProjectTasksController < ApplicationController
  before_action :set_project
  before_action :set_task, only: %i[ toggle destroy ]

  def create
    @task = @project.project_tasks.build(task_params)

    if @task.save
      load_projects_context

      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Tarea agregada / Task added."
          render_projects_content
        end
        format.html { redirect_to projects_path, notice: "Tarea agregada / Task added." }
      end
    else
      load_projects_context

      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = @task.errors.full_messages.to_sentence.presence || "Error al agregar tarea."
          render_projects_content(status: :unprocessable_entity)
        end
        format.html { redirect_to projects_path, alert: "Error al agregar tarea." }
      end
    end
  end

  def toggle
    @task.update(completed: !@task.completed)
    load_projects_context

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Logro actualizado."
        render_projects_content
      end
      format.html { redirect_to projects_path, notice: "Logro actualizado." }
    end
  end

  def destroy
    @task.destroy
    load_projects_context

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Tarea eliminada."
        render_projects_content
      end
      format.html { redirect_to projects_path, notice: "Tarea eliminada." }
    end
  end

  private

  def load_projects_context
    @projects = current_user.projects.includes(:project_tasks).order(created_at: :desc)
    @new_project = current_user.projects.build
  end

  def render_projects_content(status: :ok)
    render turbo_stream: turbo_stream.replace("projects_content", partial: "projects/content"), status: status
  end

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_task
    @task = @project.project_tasks.find(params[:id])
  end

  def task_params
    params.require(:project_task).permit(:name)
  end
end
